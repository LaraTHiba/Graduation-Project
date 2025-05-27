import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Controller class for handling authentication-related operations
class AuthController extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Attempts to log in a user with the provided credentials
  /// Returns a Map containing the user data and token if successful
  /// Throws an exception if login fails
  Future<Map<String, dynamic>> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      throw Exception('Username and password cannot be empty');
    }
    return await _apiService.login(username, password);
  }

  /// Registers a new user with the provided information
  /// Returns a Map containing the user data if successful
  /// Throws an exception if registration fails
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
    if (password != password2) {
      throw Exception('Passwords do not match');
    }

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

  /// Requests a password reset email for the provided email address
  /// Returns true if the request was successful
  /// Throws an exception if the request fails
  Future<bool> requestPasswordReset(String email) async {
    if (email.isEmpty) {
      throw Exception('Email cannot be empty');
    }
    await _apiService.requestPasswordReset(email);
    return true;
  }

  /// Resets the password using the provided token and new password
  /// Returns true if the reset was successful
  /// Throws an exception if the reset fails
  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String newPassword2,
  }) async {
    if (newPassword != newPassword2) {
      throw Exception('New passwords do not match');
    }
    await _apiService.resetPassword(
      token: token,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
    return true;
  }

  /// Changes the password for a logged-in user
  /// Returns true if the change was successful
  /// Throws an exception if the change fails
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPassword2,
  }) async {
    if (newPassword != newPassword2) {
      throw Exception('New passwords do not match');
    }
    await _apiService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
      newPassword2: newPassword2,
    );
    return true;
  }

  /// Checks if a user is currently logged in
  /// Returns true if a valid token exists
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  /// Logs out the current user
  /// Returns true if logout was successful
  /// Throws an exception if logout fails
  Future<bool> logout() async {
    return await _apiService.logout();
  }
}
