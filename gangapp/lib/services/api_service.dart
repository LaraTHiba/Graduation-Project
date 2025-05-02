import 'package:http/http.dart' as http;
import 'dart:convert';
// Conditionally import dart:io to avoid issues in web
import 'dart:io' if (dart.library.js) 'dart:typed_data' show File;
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Only import dart:io in non-web platforms
// ignore: unused_import
import 'dart:io' if (dart.library.js) 'dart:ui' as io;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // Auth endpoints
  static const String loginEndpoint = '$baseUrl/auth/login/';
  static const String registerEndpoint = '$baseUrl/auth/register/';
  static const String logoutEndpoint = '$baseUrl/auth/logout/';
  static const String changePasswordEndpoint = '$baseUrl/auth/change-password/';
  static const String resetPasswordEmailEndpoint =
      '$baseUrl/auth/reset-password-email/';
  static const String resetPasswordEndpoint =
      '$baseUrl/auth/reset-password/'; // + token/
  static const String tokenEndpoint = '$baseUrl/auth/token/';
  static const String tokenRefreshEndpoint = '$baseUrl/auth/token/refresh/';

  // Profile endpoints
  static const String myProfileEndpoint = '$baseUrl/me/';
  static const String updateProfileEndpoint = '$baseUrl/me/update/';
  static const String publicProfileEndpoint = '$baseUrl/users/'; // + username
  static const String fileUploadEndpoint = '$baseUrl/upload/';

  // Post endpoints
  static const String postsEndpoint = '$baseUrl/posts/';
  static const String userPostsEndpoint = '$baseUrl/posts/user/'; // + username
  static const String searchPostsEndpoint = '$baseUrl/posts/search/';
  static const String deletedPostsEndpoint = '$baseUrl/posts/deleted/';
  static const String restorePostEndpoint =
      '$baseUrl/posts/'; // + post_id + /restore/
  static const String hardDeletePostEndpoint =
      '$baseUrl/posts/'; // + post_id + /hard-delete/

  // Comment endpoints
  static const String commentsEndpoint =
      '$baseUrl/posts/'; // + post_id + /comments/
  static const String commentDetailEndpoint =
      '$baseUrl/comments/'; // + comment_id
  static const String userCommentsEndpoint =
      '$baseUrl/comments/user/'; // + username
  static const String deletedCommentsEndpoint = '$baseUrl/comments/deleted/';
  static const String restoreCommentEndpoint =
      '$baseUrl/comments/'; // + comment_id + /restore/
  static const String hardDeleteCommentEndpoint =
      '$baseUrl/comments/'; // + comment_id + /hard-delete/

  // Get auth token
  Future<String> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') ?? '';
  }

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(loginEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['access'] == null || data['refresh'] == null) {
          throw Exception('Invalid response format: missing tokens');
        }

        // Save tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        await prefs.setString('refresh_token', data['refresh']);
        await prefs.setString('username', username);

        // Verify tokens were saved
        final savedAccessToken = prefs.getString('access_token');
        final savedRefreshToken = prefs.getString('refresh_token');

        if (savedAccessToken == null || savedRefreshToken == null) {
          throw Exception('Failed to save authentication tokens');
        }

        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse(registerEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  // Request password reset
  Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse(resetPasswordEmailEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset request failed: ${response.body}');
    }
  }

  // Reset password with token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
    required String newPassword2,
  }) async {
    final response = await http.post(
      Uri.parse('$resetPasswordEndpoint$token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'new_password': newPassword,
        'new_password2': newPassword2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset failed: ${response.body}');
    }
  }

  // Change password for logged-in user
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    final token = await getAuthToken();

    final response = await http.post(
      Uri.parse(changePasswordEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password2': newPassword2,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Password change failed: ${response.body}');
    }
  }

  // Logout
  Future<bool> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');

    if (refreshToken == null) {
      throw Exception("No refresh token found");
    }

    final response = await http.post(
      Uri.parse(logoutEndpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'refresh_token': refreshToken,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 205) {
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      return true;
    } else {
      throw Exception("Failed to logout: ${response.body}");
    }
  }

  // Get current user profile
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    return _handleTokenRefresh(() async {
      final token = await getAuthToken();
      if (token.isEmpty) {
        throw Exception('No authentication token found. Please log in again.');
      }

      print('Fetching user profile with token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse(myProfileEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Profile response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to load profile: ${response.body}');
      }
    });
  }

  // Get public profile by username
  Future<Map<String, dynamic>> getPublicProfile(String username) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$publicProfileEndpoint$username/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  // This method should only be used on mobile platforms
  // Update profile (mobile version with File)
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String bio,
    required String location,
    required String dateOfBirth,
    dynamic profilePicture,
    dynamic backgroundImage,
  }) async {
    if (kIsWeb) {
      throw Exception(
          'This method should not be called on web platforms. Use updateProfileWeb instead.');
    }

    final token = await getAuthToken();

    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse(updateProfileEndpoint),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['full_name'] = fullName;
    request.fields['bio'] = bio;
    request.fields['location'] = location;
    request.fields['date_of_birth'] = dateOfBirth;

    // Add profile picture if selected
    if (profilePicture != null) {
      // Extract the filename from the path
      String filepath = profilePicture.path;
      String filename = filepath.split('/').last;

      // If we can't get a filename, generate one with timestamp
      if (filename.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filename = 'profile_picture_${timestamp}.jpg';
      }

      // Add original_filename field
      request.fields['profile_picture_original_filename'] = filename;

      request.files.add(await http.MultipartFile.fromPath(
        'profile_picture',
        profilePicture.path,
        filename: filename,
      ));
    }

    // Add background image if selected
    if (backgroundImage != null) {
      // Extract the filename from the path
      String filepath = backgroundImage.path;
      String filename = filepath.split('/').last;

      // If we can't get a filename, generate one with timestamp
      if (filename.isEmpty) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        filename = 'background_image_${timestamp}.jpg';
      }

      // Add original_filename field
      request.fields['background_image_original_filename'] = filename;

      request.files.add(await http.MultipartFile.fromPath(
        'background_image',
        backgroundImage.path,
        filename: filename,
      ));
    }

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Update profile (web version with Uint8List)
  Future<Map<String, dynamic>> updateProfileWeb({
    required String fullName,
    required String bio,
    required String location,
    required String dateOfBirth,
    Uint8List? profilePictureWeb,
    Uint8List? backgroundImageWeb,
  }) async {
    final token = await getAuthToken();

    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse(updateProfileEndpoint),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['full_name'] = fullName;
    request.fields['bio'] = bio;
    request.fields['location'] = location;
    request.fields['date_of_birth'] = dateOfBirth;

    // Add profile picture if selected
    if (profilePictureWeb != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'profile_picture_${timestamp}.jpg';
      request.fields['profile_picture_original_filename'] = filename;

      request.files.add(http.MultipartFile.fromBytes(
        'profile_picture',
        profilePictureWeb,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    // Add background image if selected
    if (backgroundImageWeb != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'background_image_${timestamp}.jpg';
      request.fields['background_image_original_filename'] = filename;

      request.files.add(http.MultipartFile.fromBytes(
        'background_image',
        backgroundImageWeb,
        filename: filename,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  Future<bool> refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refresh = prefs.getString('refresh_token');

      if (refresh == null) {
        print('No refresh token found');
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiService.tokenRefreshEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access'] == null) {
          print('No access token in refresh response');
          return false;
        }

        await prefs.setString('access_token', data['access']);

        // Verify token was saved
        final savedToken = prefs.getString('access_token');
        if (savedToken == null) {
          print('Failed to save new access token');
          return false;
        }

        return true;
      } else {
        print(
            'Token refresh failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  // Helper method to handle token refresh and request retry
  Future<T> _handleTokenRefresh<T>(Future<T> Function() request) async {
    try {
      // First attempt
      try {
        return await request();
      } catch (e) {
        if (e.toString().contains('401') || e.toString().contains('403')) {
          print('Token expired or invalid, attempting refresh...');

          // Try to refresh the token
          final refreshed = await refreshToken();
          if (refreshed) {
            print('Token refreshed successfully, retrying request...');
            // Retry the request with the new token
            return await request();
          } else {
            print('Token refresh failed, clearing tokens...');
            // Clear tokens if refresh failed
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('access_token');
            await prefs.remove('refresh_token');
            throw Exception('Session expired. Please log in again.');
          }
        }
        rethrow;
      }
    } catch (e) {
      print('Error in _handleTokenRefresh: $e');
      rethrow;
    }
  }

  // Get all posts
  Future<List<dynamic>> getPosts() async {
    return _handleTokenRefresh(() async {
      final token = await getAuthToken();
      if (token.isEmpty) {
        throw Exception('No authentication token found. Please log in again.');
      }

      print('Fetching posts with token: ${token.substring(0, 10)}...');

      final response = await http.get(
        Uri.parse(postsEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Posts response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to load posts: ${response.body}');
      }
    });
  }

  // Get posts by username
  Future<List<dynamic>> getUserPosts(String username) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$userPostsEndpoint$username/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user posts: ${response.body}');
    }
  }

  // Get post by ID
  Future<Map<String, dynamic>> getPost(int postId) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$postsEndpoint$postId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load post: ${response.body}');
    }
  }

  // Create post (mobile version)
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    required int interest,
    dynamic image,
  }) async {
    if (kIsWeb) {
      throw Exception(
          "For web, use createPostWeb instead. File objects are not supported on web.");
    }

    return _handleTokenRefresh(() async {
      final token = await getAuthToken();

      if (title.isEmpty || content.isEmpty) {
        throw Exception("Title, content, and interest are required.");
      }

      // For new implementation using multipart form
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(postsEndpoint),
      );

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['title'] = title;
      request.fields['content'] = content;
      request.fields['interest'] = interest.toString();

      // Add image if selected
      if (image != null) {
        try {
          // Extract the filename from the path
          String filepath = image.path;
          String filename = filepath.split('/').last;

          // If we can't get a filename, generate one with timestamp
          if (filename.isEmpty) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            filename = 'post_image_${timestamp}.jpg';
          }

          // Add original_filename field that the backend might be using
          request.fields['original_filename'] = filename;

          // Add the image directly to the post request
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            image.path,
            filename: filename,
          ));
        } catch (e) {
          throw Exception('Failed to upload image: $e');
        }
      }

      // Send the request
      try {
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to create post: ${response.body}');
        }
      } catch (e) {
        throw Exception('Error sending request: $e');
      }
    });
  }

  // Try a direct method for creating posts with image uploads
  Future<Map<String, dynamic>> createPostDirect({
    required String title,
    required String content,
    required int interest,
    Uint8List? imageBytes,
  }) async {
    final token = await getAuthToken();

    if (title.isEmpty || content.isEmpty) {
      throw Exception("Title, content, and interest are required.");
    }

    // Create the request body manually
    var request = http.MultipartRequest('POST', Uri.parse(postsEndpoint));

    // Add authorization header
    request.headers['Authorization'] = 'Bearer $token';

    // Add the text fields
    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['interest'] = interest.toString();

    // Add image if available
    if (imageBytes != null) {
      // Generate a timestamp-based filename without any space or special characters
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'post_image_${timestamp}.jpg';

      // Add the file with multiple possible field name variants
      request.fields['image_filename'] = filename;

      // Create a multipart file with the content type explicitly set
      var file = http.MultipartFile.fromBytes(
          'image', // field name
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'));

      request.files.add(file);

      print('Adding file: $filename (${imageBytes.length} bytes)');
    }

    print('Sending request to ${request.url}');
    print('Fields: ${request.fields}');
    print(
        'Files: ${request.files.map((f) => '${f.field}: ${f.filename}').join(', ')}');

    try {
      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 201) {
        var jsonResponse = jsonDecode(response.body);
        print('Success response: $jsonResponse');
        return jsonResponse;
      } else {
        print('Error response: ${response.body}');
        throw Exception(
            'Failed to create post: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception during request: $e');
      throw Exception('Error sending request: $e');
    }
  }

  // Create post for web platforms
  Future<Map<String, dynamic>> createPostWeb({
    required String title,
    required String content,
    required int interest,
    Uint8List? imageBytes,
  }) async {
    return _handleTokenRefresh(() async {
      final token = await getAuthToken();

      if (title.isEmpty || content.isEmpty) {
        throw Exception("Title, content, and interest are required.");
      }

      // Use standard http request instead of MultipartRequest for better control
      final Uri uri = Uri.parse(postsEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['title'] = title;
      request.fields['content'] = content;
      request.fields['interest'] = interest.toString();

      // Add image if selected
      if (imageBytes != null) {
        try {
          // Generate a unique filename with timestamp
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filename = 'post_image_${timestamp}.jpg';

          // Try multiple field names that Django might be looking for
          request.fields['original_filename'] = filename;
          request.fields['name'] = filename;
          request.fields['file_name'] = filename;
          request.fields['image_name'] = filename;
          request.fields['image_original_name'] = filename;
          request.fields['image_filename'] = filename;

          // Create the multipart file with explicit filename
          final multipartFile = http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: filename,
            contentType: MediaType('image', 'jpeg'),
          );

          request.files.add(multipartFile);

          // Add debugging information
          print('Uploading file with filename: $filename');
          print('Content-Type: ${multipartFile.contentType}');
          print('Field name: ${multipartFile.field}');
        } catch (e) {
          throw Exception('Failed to upload image: $e');
        }
      }

      // Send the request
      try {
        print('Sending request to $uri');
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        // Debug response
        print('Response status code: ${response.statusCode}');
        print('Response headers: ${response.headers}');

        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          print('Image URL in response: ${responseData['image']}');
          return responseData;
        } else {
          throw Exception('Failed to create post: ${response.body}');
        }
      } catch (e) {
        throw Exception('Error sending request: $e');
      }
    });
  }

  // Update post (mobile version)
  Future<Map<String, dynamic>> updatePost({
    required int postId,
    required String title,
    required String content,
    required int interest,
    dynamic image,
  }) async {
    if (kIsWeb) {
      throw Exception(
          "For web, use updatePostWeb instead. File objects are not supported on web.");
    }

    final token = await getAuthToken();

    // Create a multipart request
    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$postsEndpoint$postId/'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['interest'] = interest.toString();

    // Add image if selected
    if (image != null) {
      try {
        // Extract the filename from the path
        String filepath = image.path;
        String filename = filepath.split('/').last;

        // If we can't get a filename, generate one with timestamp
        if (filename.isEmpty) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          filename = 'post_image_${timestamp}.jpg';
        }

        // Add original_filename field that the backend might be using
        request.fields['original_filename'] = filename;

        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: filename,
        ));
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    // Send the request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update post: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }

  // Update post for web platforms
  Future<Map<String, dynamic>> updatePostWeb({
    required int postId,
    required String title,
    required String content,
    required int interest,
    Uint8List? imageBytes,
  }) async {
    final token = await getAuthToken();

    // Create a multipart request
    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse('$postsEndpoint$postId/'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['title'] = title;
    request.fields['content'] = content;
    request.fields['interest'] = interest.toString();

    // Add image if selected
    if (imageBytes != null) {
      try {
        // Generate a unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'post_image_${timestamp}.jpg';

        // Add original_filename field that the backend might be using
        request.fields['original_filename'] = filename;

        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    // Send the request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update post: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }

  // Delete post
  Future<void> deletePost(int postId) async {
    final token = await getAuthToken();

    final response = await http.delete(
      Uri.parse('$postsEndpoint$postId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete post: ${response.body}');
    }
  }

  // Get comments for a post
  Future<List<dynamic>> getComments(int postId) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$baseUrl/posts/$postId/comments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('Getting comments for post $postId: ${response.statusCode}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load comments: ${response.body}');
    }
  }

  // Create comment
  Future<Map<String, dynamic>> createComment({
    required int postId,
    required String content,
    dynamic image,
  }) async {
    final token = await getAuthToken();

    // Get the current user ID from the profile
    final userProfile = await getCurrentUserProfile();
    final userId = userProfile['user']['id'];

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts/$postId/comments/'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['content'] = content;
    request.fields['user'] = userId.toString();

    // Add image if selected
    if (image != null) {
      try {
        // Extract the filename from the path
        String filepath = image.path;
        String filename = filepath.split('/').last;

        // If we can't get a filename, generate one with timestamp
        if (filename.isEmpty) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          filename = 'comment_image_${timestamp}.jpg';
        }

        // Add original_filename field
        request.fields['original_filename'] = filename;

        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: filename,
        ));
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    // Send the request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }

  // Create comment for web
  Future<Map<String, dynamic>> createCommentWeb({
    required int postId,
    required String content,
    Uint8List? imageBytes,
  }) async {
    final token = await getAuthToken();

    // Get the current user ID from the profile
    final userProfile = await getCurrentUserProfile();
    final userId = userProfile['user']['id'];

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts/$postId/comments/'),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['content'] = content;
    request.fields['user'] = userId.toString();

    // Add image if selected
    if (imageBytes != null) {
      try {
        // Generate a unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'comment_image_${timestamp}.jpg';

        // Add original_filename field
        request.fields['original_filename'] = filename;

        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    // Send the request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Web comment request fields: ${request.fields}');
      print('Web comment response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create comment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }

  // Create reply to a comment
  Future<Map<String, dynamic>> createReply({
    required int postId,
    required int commentId,
    required String content,
    dynamic image,
  }) async {
    if (kIsWeb) {
      throw Exception("For web, use createReplyWeb instead.");
    }

    final token = await getAuthToken();

    // Get the current user ID from the profile
    final userProfile = await getCurrentUserProfile();
    final userId = userProfile['user']['id'];

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts/$postId/comments/$commentId/reply/'),
    );

    // Log the URL for debugging
    print('Creating reply at: ${request.url}');

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['content'] = content;
    request.fields['user'] = userId.toString(); // Add the required user field

    // Add image if selected
    if (image != null) {
      try {
        // Extract the filename from the path
        String filepath = image.path;
        String filename = filepath.split('/').last;

        // If we can't get a filename, generate one with timestamp
        if (filename.isEmpty) {
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          filename = 'reply_image_${timestamp}.jpg';
        }

        // Add original_filename field that the backend might be using
        request.fields['original_filename'] = filename;

        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          filename: filename,
        ));
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    // Send the request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Reply response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create reply: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }

  // Create reply for web
  Future<Map<String, dynamic>> createReplyWeb({
    required int postId,
    required int commentId,
    required String content,
    Uint8List? imageBytes,
  }) async {
    final token = await getAuthToken();

    // Get the current user ID from the profile
    final userProfile = await getCurrentUserProfile();
    final userId = userProfile['user']['id'];

    // Create multipart request
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/posts/$postId/comments/$commentId/reply/'),
    );

    // Log the URL for debugging
    print('Creating web reply at: ${request.url}');

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add text fields
    request.fields['content'] = content;
    request.fields['user'] = userId.toString(); // Add the required user field

    // Add image if selected
    if (imageBytes != null) {
      try {
        // Generate a unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'reply_image_${timestamp}.jpg';

        // Add original_filename field that the backend might be using
        request.fields['original_filename'] = filename;

        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    // Send the request
    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Web reply response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create reply: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }

  // Upload a file and get back a URL (mobile version)
  Future<Map<String, dynamic>> uploadFile(dynamic file) async {
    if (kIsWeb) {
      throw Exception(
          'This method should not be called on web platforms. Use uploadFileWeb instead.');
    }

    final token = await getAuthToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(fileUploadEndpoint),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Extract the filename from the path
    String filepath = file.path;
    String filename = filepath.split('/').last;

    // If we can't get a filename, generate one with timestamp
    if (filename.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filename = 'file_${timestamp}.jpg';
    }

    // Add original_filename field
    request.fields['original_filename'] = filename;

    // Add file
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: filename,
    ));

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }

  // Upload a file and get back a URL (web version)
  Future<Map<String, dynamic>> uploadFileWeb(
      Uint8List? fileBytes, String fileName, String contentType) async {
    final token = await getAuthToken();

    if (fileBytes == null) {
      throw Exception('File bytes cannot be null');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(fileUploadEndpoint),
    );

    // Add headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });

    // Add original_filename field
    request.fields['original_filename'] = fileName;

    // Parse content type safely
    MediaType mediaType;
    if (contentType.contains('/')) {
      final parts = contentType.split('/');
      mediaType = MediaType(parts[0], parts[1]);
    } else {
      // Default to image/jpeg if content type is invalid
      mediaType = MediaType('image', 'jpeg');
    }

    // Add file
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: mediaType,
    ));

    // Send the request
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload file: ${response.body}');
    }
  }

  // Search posts
  Future<List<dynamic>> searchPosts(String query) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$searchPostsEndpoint?search=$query'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search posts: ${response.body}');
    }
  }

  // Get deleted posts
  Future<List<dynamic>> getDeletedPosts() async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse(deletedPostsEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load deleted posts: ${response.body}');
    }
  }

  // Restore a deleted post
  Future<Map<String, dynamic>> restorePost(int postId) async {
    final token = await getAuthToken();

    final response = await http.post(
      Uri.parse('$restorePostEndpoint$postId/restore/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to restore post: ${response.body}');
    }
  }

  // Hard delete a post (permanent deletion)
  Future<void> hardDeletePost(int postId) async {
    final token = await getAuthToken();

    final response = await http.delete(
      Uri.parse('$hardDeletePostEndpoint$postId/hard-delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to permanently delete post: ${response.body}');
    }
  }

  // Get comments by user
  Future<List<dynamic>> getUserComments(String username) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$userCommentsEndpoint$username/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user comments: ${response.body}');
    }
  }

  // Get a specific comment
  Future<Map<String, dynamic>> getComment(int commentId) async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$commentDetailEndpoint$commentId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load comment: ${response.body}');
    }
  }

  // Update a comment
  Future<Map<String, dynamic>> updateComment({
    required int commentId,
    required String content,
    dynamic image,
  }) async {
    if (kIsWeb) {
      throw Exception("For web, use updateCommentWeb instead.");
    }

    final token = await getAuthToken();

    // Start with the basic content
    final Map<String, dynamic> commentData = {
      'content': content,
    };

    // Add image if selected
    if (image != null) {
      try {
        final imageUrl = await uploadFile(image);
        commentData['image'] = imageUrl['file_url'];
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    final response = await http.patch(
      Uri.parse('$commentDetailEndpoint$commentId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(commentData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update comment: ${response.body}');
    }
  }

  // Update a comment on web
  Future<Map<String, dynamic>> updateCommentWeb({
    required int commentId,
    required String content,
    Uint8List? imageBytes,
  }) async {
    final token = await getAuthToken();

    // Start with basic content
    final Map<String, dynamic> commentData = {
      'content': content,
    };

    // Add image if selected
    if (imageBytes != null) {
      try {
        // Generate a unique filename with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filename = 'comment_image_${timestamp}.jpg';

        final imageUrl =
            await uploadFileWeb(imageBytes, filename, 'image/jpeg');
        commentData['image'] = imageUrl['file_url'];
      } catch (e) {
        throw Exception('Failed to upload image: $e');
      }
    }

    final response = await http.patch(
      Uri.parse('$commentDetailEndpoint$commentId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(commentData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update comment: ${response.body}');
    }
  }

  // Delete a comment (soft delete)
  Future<void> deleteComment(int commentId) async {
    final token = await getAuthToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/comments/posts/$commentId/hard-delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete comment: ${response.body}');
    }
  }

  // Hard delete a comment (permanent deletion)
  Future<void> hardDeleteComment(int commentId) async {
    final token = await getAuthToken();

    final response = await http.delete(
      Uri.parse('$hardDeleteCommentEndpoint$commentId/hard-delete/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to permanently delete comment: ${response.body}');
    }
  }

  // Get deleted comments
  Future<List<dynamic>> getDeletedComments() async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse(deletedCommentsEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load deleted comments: ${response.body}');
    }
  }

  // Restore a deleted comment
  Future<Map<String, dynamic>> restoreComment(int commentId) async {
    final token = await getAuthToken();

    final response = await http.post(
      Uri.parse('$restoreCommentEndpoint$commentId/restore/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to restore comment: ${response.body}');
    }
  }

  // Get available interests
  Future<List<Map<String, dynamic>>> getInterests() async {
    final token = await getAuthToken();

    final response = await http.get(
      Uri.parse('$baseUrl/interests/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((interest) => interest as Map<String, dynamic>).toList();
    } else {
      throw Exception('Failed to load interests: ${response.body}');
    }
  }

  // Get first valid interest ID
  Future<int> getFirstValidInterestId() async {
    try {
      final interests = await getInterests();
      if (interests.isNotEmpty && interests[0].containsKey('id')) {
        return interests[0]['id'];
      }
      throw Exception('No valid interests found');
    } catch (e) {
      // If we can't get interests, default to 4 (you may want to change this)
      print('Error getting interests: $e, using default interest ID');
      return 4; // Try a different default ID
    }
  }

  // Soft delete a post (mark as deleted but keep in database)
  Future<void> softDeletePost(int postId) async {
    final token = await getAuthToken();

    final response = await http.delete(
      Uri.parse('$postsEndpoint$postId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to soft delete post: ${response.body}');
    }
  }

  // Generic request method with token refresh
  Future<Map<String, dynamic>> makeRequest(
    String method,
    String path, {
    dynamic body,
    Map<String, String>? queryParams,
  }) async {
    return _handleTokenRefresh(() async {
      final token = await getAuthToken();
      final uri =
          Uri.parse(baseUrl + path).replace(queryParameters: queryParams);

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(uri, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: body);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: body);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty) return {};
        return jsonDecode(response.body);
      } else {
        throw Exception('Request failed: ${response.body}');
      }
    });
  }

  // Archive post
  Future<void> archivePost(int postId) async {
    final token = await getAuthToken();

    final response = await http.post(
      Uri.parse('$postsEndpoint$postId/archive/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to archive post: ${response.body}');
    }
  }
}
