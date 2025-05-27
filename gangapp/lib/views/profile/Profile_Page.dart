import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/profile_controller.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:transparent_image/transparent_image.dart';
import '../widgets/profile_widgets.dart';
import '../../utils/email_validator.dart';
import '../widgets/profile_icon.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../languages/language.dart';
import 'package:file_picker/file_picker.dart';
import '../home/Home_Page.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  final String? username;

  const ProfilePage({Key? key, this.username}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isCurrentUser = true;
  bool _isSettingsOpen = false;
  List<Map<String, dynamic>> _userPosts = [];

  // User data
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userDetails = {};

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  // Image handling
  File? _profileImageFile;
  File? _backgroundImageFile;
  Uint8List? _profileImageWeb;
  Uint8List? _backgroundImageWeb;
  final ImagePicker _picker = ImagePicker();

  // Profile controller
  final ProfileController _profileController = ProfileController();

  // Colors
  final Color _primaryColor = Color(0xFF006C5F);
  final Color _accentColor = Color(0xFF4CAF93);

  String? _userType;
  String? _userEmail;

  File? _cvFile;
  Uint8List? _cvFileWeb;
  String? _cvFileName;

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadProfile();
    _loadUserTypeAndEmail();
  }

  Future<void> _loadUserTypeAndEmail() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userType = prefs.getString('user_type') ?? 'User';
      _userEmail = prefs.getString('email') ?? '';
    });
  }

  Future<void> _checkUserAndLoadProfile() async {
    if (widget.username != null) {
      _isCurrentUser =
          await _profileController.isCurrentUserProfile(widget.username!);
    }
    await _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profileData =
          await _profileController.getProfile(username: widget.username);

      if (!mounted) return;
      setState(() {
        _userDetails = profileData;
        _userData = profileData['user'] ?? {};
        _fullNameController.text = _userDetails['full_name'] ?? '';
        _bioController.text = _userDetails['bio'] ?? '';
        _locationController.text = _userDetails['location'] ?? '';
        _dobController.text = _userDetails['date_of_birth'] ?? '';
        _phoneNumberController.text = _userData['phone_number'] ?? '';
        _isLoading = false;
      });

      // Fetch user posts after profile data is loaded
      await _fetchUserPosts();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to load profile', 'Please try again later.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final username = widget.username ?? _userData['username'];
      if (username != null) {
        final posts = await _profileController.getUserPosts(username);
        if (!mounted) return;
        setState(() {
          _userPosts = posts;
        });
      }
    } catch (e) {
      // Don't show error dialog for posts as it's not critical
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (!mounted) return;
    setState(() => _isSaving = true);

    try {
      if (kIsWeb) {
        await _profileController.updateProfile(
          fullName: _fullNameController.text,
          bio: _bioController.text,
          location: _locationController.text,
          dateOfBirth: _dobController.text,
          profilePictureWeb: _profileImageWeb,
          backgroundImageWeb: _backgroundImageWeb,
        );
      } else {
        await _profileController.updateProfile(
          fullName: _fullNameController.text,
          bio: _bioController.text,
          location: _locationController.text,
          dateOfBirth: _dobController.text,
          profilePicture: _profileImageFile,
          backgroundImage: _backgroundImageFile,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: _primaryColor,
        ),
      );

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      await _fetchUserProfile();
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Update Failed', 'Could not update profile: $e');
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImage(ImageSource source, bool isProfilePicture) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            if (isProfilePicture) {
              _profileImageWeb = bytes;
            } else {
              _backgroundImageWeb = bytes;
            }
          });
        } else {
          setState(() {
            if (isProfilePicture) {
              _profileImageFile = File(pickedFile.path);
            } else {
              _backgroundImageFile = File(pickedFile.path);
            }
          });
        }
      }
    } catch (e) {
      _showErrorDialog('Image Selection Error', e.toString());
    }
  }

  void _showImagePickerOptions(bool isProfilePicture) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: _primaryColor),
              title: Text('Photo Library'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery, isProfilePicture);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: Icon(Icons.photo_camera, color: _primaryColor),
                title: Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera, isProfilePicture);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dobController.text.isNotEmpty
          ? DateFormat('yyyy-MM-dd').parse(_dobController.text)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: _primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    bool readOnly = false,
    Function()? onTap,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return ProfileWidgets.buildEditableField(
      label,
      controller,
      icon,
      _isEditing,
      _primaryColor,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildProfileIcon() {
    return ProfileWidgets.buildProfileIcon(
      _isLoading,
      _userDetails['profile_picture_url'],
      24,
    );
  }

  Widget _buildBackgroundImage() {
    return ProfileWidgets.buildBackgroundImage(
      _backgroundImageFile,
      _backgroundImageWeb,
      _userDetails['background_image_url'],
      _isEditing,
      _primaryColor,
      () => _showImagePickerOptions(false),
    );
  }

  Widget _buildSettingsPanel() {
    final language = context.watch<Language>();
    final isCompanyUser = _userType?.toLowerCase() == 'company';

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      right: _isSettingsOpen ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(-8, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.95),
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () =>
                              setState(() => _isSettingsOpen = false),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          language.get('settings'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isCurrentUser) ...[
                            ListTile(
                              leading: const Icon(Icons.language),
                              title: Text(language.get('language')),
                              subtitle: Text(
                                  language.currentLanguageCode == 'ar'
                                      ? 'العربية'
                                      : 'English'),
                              trailing: Switch(
                                value: language.currentLanguageCode == 'ar',
                                onChanged: (bool value) {
                                  language.setLanguage(value ? 'ar' : 'en');
                                },
                              ),
                            ),
                            const Divider(),
                            if (!isCompanyUser)
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.upload_file_rounded,
                                    color: _primaryColor,
                                  ),
                                ),
                                title: Text(language.get('Add CV')),
                                subtitle: _cvFileName != null
                                    ? Text(
                                        _cvFileName!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                                trailing: _cvFileName != null
                                    ? IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            _cvFile = null;
                                            _cvFileWeb = null;
                                            _cvFileName = null;
                                          });
                                        },
                                      )
                                    : null,
                                onTap: _showCVUploadDialog,
                              ),
                            const Divider(),
                            ListTile(
                              leading:
                                  const Icon(Icons.logout, color: Colors.red),
                              title: Text(
                                language.get('logout'),
                                style: const TextStyle(color: Colors.red),
                              ),
                              onTap: () async {
                                try {
                                  await _profileController.logout();
                                  if (mounted) {
                                    Navigator.of(context)
                                        .pushNamedAndRemoveUntil(
                                      '/login',
                                      (Route<dynamic> route) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showErrorDialog('Logout Failed',
                                        'Could not log out: $e');
                                  }
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<Language>();
    final isCompanyUser = _userType?.toLowerCase() == 'company';

    return _isLoading
        ? Scaffold(
            backgroundColor: Colors.white,
            body:
                Center(child: CircularProgressIndicator(color: _primaryColor)))
        : Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (_isSettingsOpen) {
                    setState(() => _isSettingsOpen = false);
                  }
                  FocusScope.of(context).unfocus();
                },
                child: Scaffold(
                  backgroundColor: Colors.grey[100],
                  body: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: 200.0,
                        floating: false,
                        pinned: true,
                        backgroundColor: _primaryColor,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            _isCurrentUser
                                ? ''
                                : '${_userData['username']}\'s Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          background: _buildBackgroundImage(),
                        ),
                        actions: [
                          if (_isCurrentUser)
                            _isEditing
                                ? Row(
                                    children: [
                                      if (_isSaving)
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        IconButton(
                                          icon: Icon(Icons.save),
                                          tooltip: language.get('Save'),
                                          onPressed: _updateProfile,
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.cancel),
                                        tooltip: language.get('Cancel'),
                                        onPressed: _isSaving
                                            ? null
                                            : () {
                                                setState(() {
                                                  _isEditing = false;
                                                  _fullNameController.text =
                                                      _userDetails[
                                                              'full_name'] ??
                                                          '';
                                                  _bioController.text =
                                                      _userDetails['bio'] ?? '';
                                                  _locationController.text =
                                                      _userDetails[
                                                              'location'] ??
                                                          '';
                                                  _dobController
                                                      .text = _userDetails[
                                                          'date_of_birth'] ??
                                                      '';
                                                  _phoneNumberController.text =
                                                      _userData[
                                                              'phone_number'] ??
                                                          '';
                                                  _profileImageFile = null;
                                                  _backgroundImageFile = null;
                                                  _profileImageWeb = null;
                                                  _backgroundImageWeb = null;
                                                });
                                              },
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.settings),
                                        tooltip: language.get('settings'),
                                        onPressed: () => setState(
                                            () => _isSettingsOpen = true),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        tooltip: language.get('Edit profile'),
                                        onPressed: () =>
                                            setState(() => _isEditing = true),
                                      ),
                                    ],
                                  ),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Stack(
                                    children: [
                                      Material(
                                        elevation: 4,
                                        shape: CircleBorder(),
                                        child: GestureDetector(
                                          onTap: _isEditing
                                              ? () =>
                                                  _showImagePickerOptions(true)
                                              : null,
                                          child: Container(
                                            width: 124,
                                            height: 124,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey.shade200,
                                            ),
                                            child: ClipOval(
                                              child: _userDetails[
                                                              'profile_picture_url'] !=
                                                          null &&
                                                      _userDetails[
                                                              'profile_picture_url']
                                                          .toString()
                                                          .isNotEmpty
                                                  ? Image.network(
                                                      _userDetails[
                                                          'profile_picture_url'],
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          color: Colors
                                                              .grey.shade300,
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 80,
                                                            color: Colors
                                                                .grey.shade400,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Icon(Icons.person,
                                                      size: 80,
                                                      color:
                                                          Colors.grey.shade400),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_isEditing)
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _primaryColor,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 5,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Center(
                                  child: Column(
                                    children: [
                                      Text(
                                        _userData['username'] ?? '',
                                        style: GoogleFonts.mukta(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      if (_userDetails['bio']?.isNotEmpty ??
                                          false)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 12),
                                          child: Text(
                                            _userDetails['bio'] ?? '',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.mukta(
                                              fontSize: 16,
                                              color: Colors.grey[600],
                                              height: 1.5,
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 8),
                                      Text(
                                        _userData['email'] ?? '',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isEditing) ...[
                                  SizedBox(height: 24),
                                  Text(
                                    language.get('Profile Details'),
                                    style: GoogleFonts.mukta(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildEditableField(
                                    language.get('Full Name'),
                                    _fullNameController,
                                    Icons.person,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return language
                                            .get('Please enter your name');
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 12),
                                  _buildEditableField(
                                    language.get('Bio'),
                                    _bioController,
                                    Icons.description,
                                    maxLines: 3,
                                  ),
                                  SizedBox(height: 12),
                                  _buildEditableField(
                                    language.get('Location'),
                                    _locationController,
                                    Icons.location_on,
                                  ),
                                  SizedBox(height: 12),
                                  _buildEditableField(
                                    language.get('Date of Birth'),
                                    _dobController,
                                    Icons.calendar_today,
                                    readOnly: true,
                                    onTap: _isEditing
                                        ? () => _selectDate(context)
                                        : null,
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    language.get('Account Information'),
                                    style: GoogleFonts.mukta(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildEditableField(
                                    language.get('Phone Number'),
                                    _phoneNumberController,
                                    Icons.phone,
                                    onChanged: (value) {
                                      setState(() {
                                        _userData['phone_number'] = value;
                                      });
                                    },
                                  ),
                                  SizedBox(height: 12),
                                  _buildEditableField(
                                    language.get('User Type'),
                                    TextEditingController(
                                        text: _userData['user_type'] ??
                                            'Standard'),
                                    Icons.person,
                                    readOnly: true,
                                  ),
                                ],
                                SizedBox(height: 24),
                                if (!isCompanyUser) _buildCVSection(),
                                SizedBox(height: 24),
                                Text(
                                  language.get('posts'),
                                  style: GoogleFonts.mukta(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                                SizedBox(height: 16),
                                _buildPostsGrid(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  bottomNavigationBar: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      color: const Color(0xFF006C5F),
                      height: 60,
                      child: BottomNavigationBar(
                        currentIndex: isCompanyUser ? 2 : 3,
                        onTap: (index) {
                          if (isCompanyUser) {
                            // Company: Home (0), Explore (1), Profile (2)
                            switch (index) {
                              case 0:
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()),
                                );
                                break;
                              case 1:
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()),
                                );
                                break;
                              case 2:
                                // Already on profile
                                break;
                            }
                          } else {
                            // User: Home (0), Groups (1), Explore (2), Profile (3)
                            switch (index) {
                              case 0:
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()),
                                );
                                break;
                              case 1:
                                // TODO: Implement groups navigation
                                break;
                              case 2:
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const HomePage()),
                                );
                                break;
                              case 3:
                                // Already on profile
                                break;
                            }
                          }
                        },
                        type: BottomNavigationBarType.fixed,
                        backgroundColor: const Color(0xFF006C5F),
                        elevation: 8,
                        selectedItemColor: Colors.white,
                        unselectedItemColor: Colors.white70,
                        selectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                        items: isCompanyUser
                            ? [
                                BottomNavigationBarItem(
                                  icon: const Icon(Icons.home_rounded),
                                  label: language.get('home'),
                                ),
                                BottomNavigationBarItem(
                                  icon: const Icon(Icons.explore_rounded),
                                  label: language.get('explore'),
                                ),
                                BottomNavigationBarItem(
                                  icon: ProfileIcon(
                                    imageUrl:
                                        _userDetails['profile_picture_url'],
                                    isLoading: _isLoading,
                                    size: 26,
                                    iconColor: Colors.white,
                                  ),
                                  label: language.get('profile'),
                                ),
                              ]
                            : [
                                BottomNavigationBarItem(
                                  icon: const Icon(Icons.home_rounded),
                                  label: language.get('home'),
                                ),
                                BottomNavigationBarItem(
                                  icon: const Icon(Icons.group_rounded),
                                  label: language.get('groups'),
                                ),
                                BottomNavigationBarItem(
                                  icon: const Icon(Icons.explore_rounded),
                                  label: language.get('explore'),
                                ),
                                BottomNavigationBarItem(
                                  icon: ProfileIcon(
                                    imageUrl:
                                        _userDetails['profile_picture_url'],
                                    isLoading: _isLoading,
                                    size: 26,
                                    iconColor: Colors.white,
                                  ),
                                  label: language.get('profile'),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildSettingsPanel(),
            ],
          );
  }

  Widget _buildPostsGrid() {
    if (_userPosts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.post_add,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: GoogleFonts.mukta(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first post to share with the community',
              style: GoogleFonts.mukta(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUserPosts,
      color: _primaryColor,
      backgroundColor: Colors.white,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1,
        ),
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          final post = _userPosts[index];
          // Try all possible image keys
          final imageUrl =
              post['image_url'] ?? post['image'] ?? post['imageUrl'];
          return Hero(
            tag: 'post_${post['id']}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Navigate to post detail
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null && imageUrl.toString().isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      post['title'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post['likes_count'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.comment,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${post['comments_count'] ?? 0}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null) {
        if (kIsWeb) {
          setState(() {
            _cvFileWeb = result.files.single.bytes;
            _cvFileName = result.files.single.name;
          });
        } else {
          setState(() {
            _cvFile = File(result.files.single.path!);
            _cvFileName = result.files.single.name;
          });
        }
      }
    } catch (e) {
      _showErrorDialog('CV Upload Error', e.toString());
    }
  }

  Future<void> _uploadCV() async {
    try {
      if (!mounted) return;
      setState(() => _isSaving = true);

      final uploadResult = await _profileController.uploadCV(
        cvFile: _cvFile,
        cvFileWeb: _cvFileWeb,
        fileName: _cvFileName,
        fileType: 'cv',
      );

      if (uploadResult['error'] != null) {
        _showErrorDialog('CV Upload Error', uploadResult['error']);
        setState(() => _isSaving = false);
        return;
      }

      await _fetchUserProfile();
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CV uploaded successfully'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showErrorDialog('CV Upload Error', e.toString());
    }
  }

  void _showCVUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  size: 48,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Upload Your CV',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Supported formats: PDF, DOC, DOCX',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              if (_cvFileName != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: _primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _cvFileName!,
                          style: const TextStyle(fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _cvFile = null;
                            _cvFileWeb = null;
                            _cvFileName = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (_cvFileName == null)
                    ElevatedButton(
                      onPressed: () async {
                        await _pickCV();
                        if (_cvFileName != null) {
                          await _uploadCV();
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Choose File',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchCVUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open CV'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildCVSection() {
    final cvUrl = _userDetails['cv_url'];
    final savedFileName = _userDetails['cv_original_filename'] ?? 'CV';

    if (cvUrl == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CV',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _cvFileName ?? savedFileName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (_isCurrentUser)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (!mounted) return;
                        setState(() {
                          _cvFile = null;
                          _cvFileWeb = null;
                          _cvFileName = null;
                          _userDetails['cv_url'] = null;
                          _userDetails['cv_original_filename'] = null;
                        });
                        // Update the profile to remove the CV
                        await _profileController.updateProfile(
                          fullName: _fullNameController.text,
                          bio: _bioController.text,
                          location: _locationController.text,
                          dateOfBirth: _dobController.text,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('CV removed'),
                            backgroundColor: _primaryColor,
                          ),
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: () {
                      if (cvUrl != null) {
                        _launchCVUrl(cvUrl);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }
}
