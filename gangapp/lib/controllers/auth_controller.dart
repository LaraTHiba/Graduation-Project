import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController {
  final ApiService _apiService = ApiService();

  // Login user
  Future<Map<String, dynamic>> login(String username, String password) async {
    return await _apiService.login(username, password);
  }

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? userType,
  }) async {
    final data = {
      'username': username,
      'email': email,
      'password': password,
      'password2': password2,
      'first_name': firstName,
      'last_name': lastName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (userType != null) 'user_type': userType,
    };

    return await _apiService.register(data);
  }

  // Request password reset email
  Future<bool> requestPasswordReset(String email) async {
    await _apiService.requestPasswordReset(email);
    return true;
  }

  // Reset password with token
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String newPassword2,
  }) async {
    await _apiService.resetPassword(
      token: token,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
    return true;
  }

  // Change password (for logged-in users)
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    await _apiService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
    return true;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  // Logout user
  Future<bool> logout() async {
    return await _apiService.logout();
  }
}
