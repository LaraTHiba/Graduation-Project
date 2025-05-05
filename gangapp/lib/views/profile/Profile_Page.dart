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
import '../groups/groups.dart';

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

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadProfile();
  }

  Future<void> _checkUserAndLoadProfile() async {
    if (widget.username != null) {
      _isCurrentUser =
          await _profileController.isCurrentUserProfile(widget.username!);
    }
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final profileData =
          await _profileController.getProfile(username: widget.username);

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
      _showErrorDialog('Failed to load profile', 'Please try again later.');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUserPosts() async {
    try {
      final username = widget.username ?? _userData['username'];
      if (username != null) {
        final posts = await _profileController.getUserPosts(username);
        setState(() {
          _userPosts = posts;
        });
      }
    } catch (e) {
      print('Error fetching user posts: $e');
      // Don't show error dialog for posts as it's not critical
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

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

      _fetchUserProfile();
    } catch (e) {
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
    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      right: _isSettingsOpen ? 0 : -300,
      top: 0,
      bottom: 0,
      width: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _isSettingsOpen = false),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.check : Icons.edit,
                        color: Colors.white),
                    onPressed: () {
                      if (_isEditing) _updateProfile();
                      setState(() => _isEditing = !_isEditing);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Details',
                      style: GoogleFonts.mukta(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildEditableField(
                      'Full Name',
                      _fullNameController,
                      Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    _buildEditableField(
                      'Bio',
                      _bioController,
                      Icons.description,
                      maxLines: 3,
                    ),
                    SizedBox(height: 12),
                    _buildEditableField(
                      'Location',
                      _locationController,
                      Icons.location_on,
                    ),
                    SizedBox(height: 12),
                    _buildEditableField(
                      'Date of Birth',
                      _dobController,
                      Icons.calendar_today,
                      readOnly: true,
                      onTap: _isEditing ? () => _selectDate(context) : null,
                    ),
                    SizedBox(height: 24),
                    if (_isCurrentUser) ...[
                      Text(
                        'Account Information',
                        style: GoogleFonts.mukta(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildEditableField(
                        'Phone Number',
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
                        'User Type',
                        TextEditingController(
                            text: _userData['user_type'] ?? 'Standard'),
                        Icons.person,
                        readOnly: true,
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: () async {
                            try {
                              await _profileController.logout();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                '/login',
                                (Route<dynamic> route) => false,
                              );
                            } catch (e) {
                              _showErrorDialog(
                                  'Logout Failed', 'Could not log out: $e');
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
                              Text(
                                post['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

  @override
  Widget build(BuildContext context) {
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
                                          tooltip: 'Save changes',
                                          onPressed: _updateProfile,
                                        ),
                                      IconButton(
                                        icon: Icon(Icons.cancel),
                                        tooltip: 'Cancel editing',
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
                                        tooltip: 'Settings',
                                        onPressed: () => setState(
                                            () => _isSettingsOpen = true),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        tooltip: 'Edit profile',
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
                                SizedBox(height: 24),
                                Text(
                                  'Posts',
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
                  bottomNavigationBar: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                      child: Container(
                        height: 70,
                        color: _primaryColor,
                        child: BottomNavigationBar(
                          currentIndex: 3,
                          onTap: (index) {
                            switch (index) {
                              case 0:
                                Navigator.pushReplacementNamed(
                                    context, '/home');
                                break;
                              case 1:
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const GroupsPage()),
                                );
                                break;
                              case 2:
                                Navigator.pushReplacementNamed(
                                    context, '/explore');
                                break;
                              case 3:
                                break;
                            }
                          },
                          type: BottomNavigationBarType.fixed,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          selectedItemColor: Colors.white,
                          unselectedItemColor: Colors.white.withOpacity(0.6),
                          selectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          unselectedLabelStyle: TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                          items: [
                            BottomNavigationBarItem(
                              icon: Icon(Icons.home_rounded, size: 24),
                              label: 'Home',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.groups_rounded, size: 24),
                              label: 'Groups',
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(Icons.explore_rounded, size: 24),
                              label: 'Explore',
                            ),
                            BottomNavigationBarItem(
                              icon: _buildProfileIcon(),
                              label: 'Profile',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _buildSettingsPanel(),
            ],
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
