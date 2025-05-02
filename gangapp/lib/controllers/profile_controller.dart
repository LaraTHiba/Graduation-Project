import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfileController {
  final ApiService _apiService = ApiService();

  // Current user's username (cached)
  String? _currentUsername;

  // Get current user's username
  Future<String?> getCurrentUsername() async {
    if (_currentUsername != null) {
      return _currentUsername;
    }

    try {
      final profile = await _apiService.getCurrentUserProfile();
      _currentUsername = profile['user']['username'];
      return _currentUsername;
    } catch (e) {
      print('Error getting current username: $e');
      return null;
    }
  }

  // Check if profile is for current user
  Future<bool> isCurrentUserProfile(String username) async {
    final currentUsername = await getCurrentUsername();
    return currentUsername == username;
  }

  // Get profile (handles both current user and other users)
  Future<Map<String, dynamic>> getProfile({String? username}) async {
    try {
      if (username == null) {
        // Get current user's profile
        return await _apiService.getCurrentUserProfile();
      } else {
        // First check if the requested profile is the current user's
        final currentUsername = await getCurrentUsername();
        if (username == currentUsername) {
          return await _apiService.getCurrentUserProfile();
        } else {
          // Get another user's profile
          return await _apiService.getPublicProfile(username);
        }
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  // Update user profile
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
      } else {
        return await _apiService.updateProfile(
          fullName: fullName,
          bio: bio,
          location: location,
          dateOfBirth: dateOfBirth,
          profilePicture: profilePicture,
          backgroundImage: backgroundImage,
        );
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Logout user
  // Future<bool> logout() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final refreshToken = prefs.getString('refresh_token');
  //
  //   if (refreshToken == null) {
  //     throw Exception('No refresh token found. User may not be logged in.');
  //   }
  //
  //   try {
  //     final response = await http.post(
  //       Uri.parse('http://10.0.2.2:8000/api/auth/logout/'),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({'refresh_token': refreshToken}),
  //     );
  //
  //     if (response.statusCode == 200 || response.statusCode == 205) {
  //       await prefs.remove('access_token');
  //       await prefs.remove('refresh_token');
  //       return true;
  //     } else {
  //       print("Logout failed: ${response.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     throw Exception("Failed to logout: $e");
  //   }
  // }

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

  // Delete user account
  // Future<bool> deleteAccount() async {
  //   try {
  //     final result = await _apiService.deleteAccount();
  //     if (result) {
  //       _currentUsername = null;
  //     }
  //     return result;
  //   } catch (e) {
  //     throw Exception('Failed to delete account: $e');
  //   }
  // }
}
