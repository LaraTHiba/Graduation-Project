import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post.dart';
import '../services/api_service.dart';
import '../services/post_service.dart';
import 'profile_controller.dart';

/// Controller class for managing home page operations
class HomeController {
  final ProfileController _profileController = ProfileController();
  final ApiService _apiService = ApiService();
  final PostService _postService = PostService();

  /// Loads user type and email from shared preferences
  Future<Map<String, String>> loadUserTypeAndEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userType': prefs.getString('user_type') ?? 'User',
      'email': prefs.getString('email') ?? '',
    };
  }

  /// Fetches the current user's profile data
  Future<String?> fetchUserProfile() async {
    try {
      final profileData = await _profileController.getProfile();
      return profileData['profile_picture_url'] as String?;
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  /// Fetches all posts
  Future<List<Post>> fetchPosts() async {
    final response = await _apiService.getPosts();
    return response.map((json) => Post.fromJson(json)).toList();
  }

  /// Creates a new post
  ///
  /// [title] The post title
  /// [content] The post content
  /// [image] Optional image file (File for mobile, Uint8List for web)
  Future<void> createPost({
    required String title,
    required String content,
    dynamic image,
  }) async {
    if (title.isEmpty) {
      throw Exception("Title cannot be empty");
    }
    if (content.isEmpty) {
      throw Exception("Content cannot be empty");
    }

    await _postService.createPost(
      title: title,
      content: content,
      interest: 1, // TODO: Make this configurable
      image: image,
    );
  }

  /// Checks if the user can access groups based on their type
  bool canAccessGroups(String userType) {
    return userType != 'Company';
  }

  /// Handles navigation based on the selected tab and user type
  bool shouldNavigate(int index, String userType) {
    if (userType == 'Company') {
      return index == 2 || index == 3; // Only allow Explore and Profile
    }
    return index >= 1; // Allow all except Home (which is handled differently)
  }

  /// Gets the route name for the selected tab
  String? getRouteForTab(int index) {
    switch (index) {
      case 1:
        return '/groups';
      case 2:
        return '/explore';
      default:
        return null;
    }
  }
}
