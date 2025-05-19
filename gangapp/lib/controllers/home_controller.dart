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

    // Get the first valid interest ID
    final interests = await _apiService.getInterests();
    if (interests.isEmpty) {
      throw Exception("No valid interests found");
    }
    final interestId = interests[0]['id'];

    await _postService.createPost(
      title: title,
      content: content,
      interest: interestId,
      image: image,
    );
  }

  /// Gets the route name for the selected tab
  String? getRouteForTab(int index) {
    switch (index) {
      // case 1:
      //   return '/groups';
      case 2:
        return '/explore';
      default:
        return null;
    }
  }
}
