import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AIService {
  static const String baseUrl =
      'http://192.168.88.10:8000'; // For Android emulator
  // static const String baseUrl = 'http://localhost:8000';  // For iOS simulator
  final ApiService _apiService = ApiService();

  Future<String> sendMessage(String message) async {
    try {
      final jwtToken = await _apiService.getAuthToken();
      print('AIService: Using JWT token: $jwtToken');

      final response = await http.post(
        Uri.parse('$baseUrl/api/ai/chat/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $jwtToken'
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['error'] ?? 'Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}
