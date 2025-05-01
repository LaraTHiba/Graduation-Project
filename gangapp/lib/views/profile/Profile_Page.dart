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
  bool _wasEdited = false;
  int _currentIndex = 3;

  // User data
  Map<String, dynamic> _userData = {};
  Map<String, dynamic> _userDetails = {};

  // Track which fields were edited
  Map<String, bool> _editedFields = {
    'full_name': false,
    'bio': false,
    'location': false,
    'date_of_birth': false,
  };

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Previous values for detecting changes
  String _prevFullName = '';
  String _prevBio = '';
  String _prevLocation = '';
  String _prevDob = '';

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
  final Color _updatedFieldColor =
      Color(0xFFE6F5F2); // Light green background for updated fields

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
    setState(() {
      _isLoading = true;
    });

    try {
      final profileData = await _profileController.getProfile(
        username: widget.username,
      );

      setState(() {
        _userDetails = profileData;
        _userData = profileData['user'] ?? {};

        // Set form values
        _fullNameController.text = _userDetails['full_name'] ?? '';
        _bioController.text = _userDetails['bio'] ?? '';
        _locationController.text = _userDetails['location'] ?? '';
        _dobController.text = _userDetails['date_of_birth'] ?? '';

        // Store previous values
        _prevFullName = _fullNameController.text;
        _prevBio = _bioController.text;
        _prevLocation = _locationController.text;
        _prevDob = _dobController.text;

        _isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('Failed to load profile', 'Please try again later.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Check which fields were edited
    _editedFields['full_name'] = _fullNameController.text != _prevFullName;
    _editedFields['bio'] = _bioController.text != _prevBio;
    _editedFields['location'] = _locationController.text != _prevLocation;
    _editedFields['date_of_birth'] = _dobController.text != _prevDob;

    // Set flag if any field was edited
    _wasEdited = _editedFields.values.contains(true) ||
        _profileImageFile != null ||
        _backgroundImageFile != null ||
        _profileImageWeb != null ||
        _backgroundImageWeb != null;

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

      // Update previous values
      _prevFullName = _fullNameController.text;
      _prevBio = _bioController.text;
      _prevLocation = _locationController.text;
      _prevDob = _dobController.text;

      // Refresh profile data from backend
      _fetchUserProfile();

      // Wait 30 seconds before resetting the "updated" indicators
      if (_wasEdited) {
        Future.delayed(Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _wasEdited = false;
              _editedFields = {
                'full_name': false,
                'bio': false,
                'location': false,
                'date_of_birth': false,
              };
            });
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Update Failed', 'Could not update profile: $e');
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source, bool isProfilePicture) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

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
          // For mobile, use File
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
      builder: (context) {
        return SafeArea(
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
        );
      },
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
            onPressed: () {
              Navigator.pop(context);
            },
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
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Widget buildTextField(
      String label, TextEditingController controller, bool isEditing,
      {int maxLines = 1,
      IconData? icon,
      Function()? onTap,
      bool readOnly = false}) {
    // Determine if this field was edited
    bool wasEdited = false;
    String fieldKey = '';

    if (label == 'Full Name') {
      fieldKey = 'full_name';
      wasEdited = _editedFields['full_name'] ?? false;
    } else if (label == 'Bio') {
      fieldKey = 'bio';
      wasEdited = _editedFields['bio'] ?? false;
    } else if (label == 'Location') {
      fieldKey = 'location';
      wasEdited = _editedFields['location'] ?? false;
    } else if (label == 'Date of Birth') {
      fieldKey = 'date_of_birth';
      wasEdited = _editedFields['date_of_birth'] ?? false;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.mukta(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: 8),
          isEditing
              ? TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    prefixIcon:
                        icon != null ? Icon(icon, color: _primaryColor) : null,
                    filled: false,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: label == 'Full Name'
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        }
                      : null,
                )
              : Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: wasEdited && _wasEdited
                        ? _updatedFieldColor
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            color: wasEdited && _wasEdited
                                ? _primaryColor
                                : Colors.grey.shade600),
                        SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          controller.text.isNotEmpty
                              ? controller.text
                              : 'Not specified',
                          style: TextStyle(
                            fontSize: 16,
                            color: wasEdited && _wasEdited
                                ? _primaryColor
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (wasEdited && _wasEdited)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Updated',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  DecorationImage? _getBackgroundImage() {
    if (_backgroundImageFile != null && !kIsWeb) {
      return DecorationImage(
        image: FileImage(_backgroundImageFile!),
        fit: BoxFit.cover,
      );
    } else if (_backgroundImageWeb != null && kIsWeb) {
      return DecorationImage(
        image: MemoryImage(_backgroundImageWeb!),
        fit: BoxFit.cover,
      );
    } else if (_userDetails['background_image_url'] != null &&
        _userDetails['background_image_url'].toString().isNotEmpty) {
      try {
        return DecorationImage(
          image: NetworkImage(_userDetails['background_image_url']),
          fit: BoxFit.cover,
        );
      } catch (e) {
        print('Failed to load background image: $e');
        return null;
      }
    }
    return null;
  }

  ImageProvider? _getProfileImage() {
    if (_profileImageFile != null && !kIsWeb) {
      return FileImage(_profileImageFile!);
    } else if (_profileImageWeb != null && kIsWeb) {
      return MemoryImage(_profileImageWeb!);
    } else if (_userDetails['profile_picture_url'] != null &&
        _userDetails['profile_picture_url'].toString().isNotEmpty) {
      try {
        return NetworkImage(
          _userDetails['profile_picture_url'],
          // Handle network errors with optional error handling
        );
      } catch (e) {
        print('Error loading profile image: $e');
        return null;
      }
    }
    return null;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    switch (index) {
      case 0: // Home
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1: // Groups
        Navigator.pushReplacementNamed(context, '/groups');
        break;
      case 2: // Explore
        Navigator.pushReplacementNamed(context, '/explore');
        break;
      case 3: // Profile
        // Already on profile page
        break;
    }
  }

  Widget _buildProfileIcon() {
    if (_isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (_userDetails['profile_picture_url'] != null &&
        _userDetails['profile_picture_url'].toString().isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _userDetails['profile_picture_url'],
          width: 24,
          height: 24,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.person_rounded, size: 24, color: Colors.white);
          },
        ),
      );
    }

    return Icon(Icons.person_rounded, size: 24, color: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? Scaffold(
            backgroundColor: Colors.white,
            body:
                Center(child: CircularProgressIndicator(color: _primaryColor)))
        : GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
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
                            ? 'My Profile'
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
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: Colors.grey.shade300,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background placeholder or fallback
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.teal.shade200,
                                        Colors.teal.shade700,
                                      ],
                                    ),
                                  ),
                                ),
                                // Actual background image with fade-in effect
                                if (_backgroundImageFile != null && !kIsWeb)
                                  Image.file(
                                    _backgroundImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                else if (_backgroundImageWeb != null && kIsWeb)
                                  Image.memory(
                                    _backgroundImageWeb!,
                                    fit: BoxFit.cover,
                                  )
                                else if (_userDetails['background_image_url'] !=
                                        null &&
                                    _userDetails['background_image_url']
                                        .toString()
                                        .isNotEmpty)
                                  FadeInImage.memoryNetwork(
                                    placeholder: kTransparentImage,
                                    image: _userDetails['background_image_url'],
                                    fit: BoxFit.cover,
                                    imageErrorBuilder:
                                        (context, error, stackTrace) {
                                      print('Error loading background: $error');
                                      // Just return an empty container to let the placeholder show
                                      return SizedBox.shrink();
                                    },
                                  ),
                              ],
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
                          if (_isEditing)
                            Positioned(
                              right: 20,
                              bottom: 80,
                              child: GestureDetector(
                                onTap: () => _showImagePickerOptions(false),
                                child: Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          if (_wasEdited &&
                              (_backgroundImageFile != null ||
                                  _backgroundImageWeb != null))
                            Positioned(
                              right: 16,
                              top: 50,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Background Updated',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
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
                                              // Reset form values
                                              _fullNameController.text =
                                                  _userDetails['full_name'] ??
                                                      '';
                                              _bioController.text =
                                                  _userDetails['bio'] ?? '';
                                              _locationController.text =
                                                  _userDetails['location'] ??
                                                      '';
                                              _dobController.text =
                                                  _userDetails[
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
                                    icon: Icon(Icons.refresh),
                                    tooltip: 'Refresh profile',
                                    onPressed: _fetchUserProfile,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    tooltip: 'Edit profile',
                                    onPressed: () {
                                      setState(() {
                                        _isEditing = true;
                                      });
                                    },
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
                            // Profile picture
                            Center(
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: _isEditing
                                        ? () => _showImagePickerOptions(true)
                                        : null,
                                    child: Material(
                                      elevation: 4,
                                      shape: CircleBorder(),
                                      child: Container(
                                        width: 124,
                                        height: 124,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade200,
                                        ),
                                        child: ClipOval(
                                          child: _getProfileImage() != null
                                              ? Image(
                                                  image: _getProfileImage()!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    // Show a placeholder on error
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade300,
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
                                                  color: Colors.grey.shade400),
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
                                              color:
                                                  Colors.black.withOpacity(0.2),
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
                                  if (_wasEdited &&
                                      (_profileImageFile != null ||
                                          _profileImageWeb != null))
                                    Positioned(
                                      right: -10,
                                      top: 0,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 3,
                                              offset: Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check_circle,
                                                color: Colors.white, size: 12),
                                            SizedBox(width: 4),
                                            Text(
                                              'Updated',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),

                            // Email
                            Center(
                              child: Text(
                                _userData['email'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            SizedBox(height: 24),

                            // Profile details section
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: EdgeInsets.all(20),
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
                                  buildTextField('Full Name',
                                      _fullNameController, _isEditing),
                                  buildTextField(
                                      'Bio', _bioController, _isEditing,
                                      maxLines: 3),
                                  buildTextField('Location',
                                      _locationController, _isEditing,
                                      icon: Icons.location_on),
                                  buildTextField('Date of Birth',
                                      _dobController, _isEditing,
                                      icon: Icons.calendar_today,
                                      onTap: _isEditing
                                          ? () => _selectDate(context)
                                          : null,
                                      readOnly: true),
                                ],
                              ),
                            ),

                            if (_isCurrentUser && !_isEditing) ...[
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Information',
                                      style: GoogleFonts.mukta(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                _primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.phone,
                                              size: 20, color: _primaryColor),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _userData['phone_number'] ??
                                                'Not provided',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color:
                                                _primaryColor.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.person,
                                              size: 20, color: _primaryColor),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'User Type: ${_userData['user_type'] ?? 'Standard'}',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Add a logout button at the bottom
                  if (_isCurrentUser) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: TextButton(
                            onPressed: () async {
                              try {
                                await _profileController.logout();
                                // Navigate to login screen after logout
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/login',
                                  (Route<dynamic> route) => false,
                                );
                              } catch (e) {
                                _showErrorDialog(
                                  'Logout Failed',
                                  'Could not log out: $e',
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
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
                      ),
                    ),
                  ],
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: Container(
                    height: 70,
                    color: _primaryColor,
                    child: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
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
          );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}
