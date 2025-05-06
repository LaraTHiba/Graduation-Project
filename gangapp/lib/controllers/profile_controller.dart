import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';

/// Controller class for managing user profile operations
class ProfileController {
  final ApiService _apiService = ApiService();

  /// Cached username of the current user
  String? _currentUsername;

  /// Retrieves the current user's username, using cache if available
  Future<String?> getCurrentUsername() async {
    if (_currentUsername != null) {
      return _currentUsername;
    }

    try {
      final profile = await _apiService.getCurrentUserProfile();
      _currentUsername = profile['user']['username'] as String;
      return _currentUsername;
    } catch (e) {
      debugPrint('Error getting current username: $e');
      return null;
    }
  }

  /// Checks if the given profile belongs to the current user
  Future<bool> isCurrentUserProfile(String username) async {
    final currentUsername = await getCurrentUsername();
    return currentUsername == username;
  }

  /// Retrieves a user profile
  ///
  /// If [username] is null, returns the current user's profile
  /// If [username] is provided, returns that user's public profile
  /// Returns the current user's profile if the requested username matches the current user
  Future<Map<String, dynamic>> getProfile({String? username}) async {
    try {
      if (username == null) {
        return await _apiService.getCurrentUserProfile();
      }

      final currentUsername = await getCurrentUsername();
      if (username == currentUsername) {
        return await _apiService.getCurrentUserProfile();
      }

      return await _apiService.getPublicProfile(username);
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  /// Updates the current user's profile
  ///
  /// Handles both web and mobile platforms differently for image uploads
  ///
  /// [fullName] The user's full name
  /// [bio] The user's biography
  /// [location] The user's location
  /// [dateOfBirth] The user's date of birth
  /// [profilePicture] Profile picture file (mobile only)
  /// [backgroundImage] Background image file (mobile only)
  /// [profilePictureWeb] Profile picture bytes (web only)
  /// [backgroundImageWeb] Background image bytes (web only)
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String bio,
    required String location,
    required String dateOfBirth,
    File? profilePicture,
    File? backgroundImage,
    Uint8List? profilePictureWeb,
    Uint8List? backgroundImageWeb,
  }) async {
    try {
      if (kIsWeb) {
        return await _apiService.updateProfileWeb(
          fullName: fullName,
          bio: bio,
          location: location,
          dateOfBirth: dateOfBirth,
          profilePictureWeb: profilePictureWeb,
          backgroundImageWeb: backgroundImageWeb,
        );
      }

      return await _apiService.updateProfile(
        fullName: fullName,
        bio: bio,
        location: location,
        dateOfBirth: dateOfBirth,
        profilePicture: profilePicture,
        backgroundImage: backgroundImage,
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Logs out the current user and clears cached data
  Future<bool> logout() async {
    try {
      final result = await _apiService.logout();
      if (result) {
        _currentUsername = null;
      }
      return result;
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  /// Retrieves posts made by a specific user
  Future<List<Map<String, dynamic>>> getUserPosts(String username) async {
    try {
      final response = await _apiService.getUserPosts(username);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch user posts: $e');
    }
  }
}
