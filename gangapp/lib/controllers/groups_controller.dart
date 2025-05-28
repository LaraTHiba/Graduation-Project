import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class GroupsController {
  final String baseUrl = ApiConfig.baseUrl;

  Future<List<Map<String, dynamic>>> getAvailableGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/groups/available/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load available groups');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMyGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/groups/my_groups/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load my groups');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/groups/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load groups');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/groups/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create group');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> joinGroup(int groupId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/groups/$groupId/join/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to join group');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> leaveGroup(int groupId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/groups/$groupId/leave/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to leave group');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
