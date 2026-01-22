import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Android Emulator uses 10.0.2.2 usually, but for physical device or iOS it might differ.
  // Using 10.0.2.2 for Android emulator default.
  // Ideally this should be configurable.
  static const String baseUrl =
      'http://10.0.2.2:80/api/v1'; // Emulator loopback to host

  static String? _accessToken;
  static String? _currentName;

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/users/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final token = data['token']['access'];
        final refreshToken = data['token']['refresh'];

        // Save to static memory
        _accessToken = token;
        _currentName = data['name'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        if (refreshToken != null) {
          await prefs.setString('refresh_token', refreshToken);
        }
        if (_currentName != null) {
          await prefs.setString('user_name', _currentName!);
        }

        return data;
      } else {
        throw Exception('Login failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  static Future<Map<String, dynamic>> signup(
    String phone,
    String password,
    String name,
  ) async {
    final url = Uri.parse('$baseUrl/users/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password, 'name': name}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Signup failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  static Future<String> getAccessToken() async {
    if (_accessToken != null && _accessToken!.isNotEmpty) return _accessToken!;
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');

    if (_accessToken == null || _accessToken!.isEmpty) {
      print("ApiService: No access token found.");
      return '';
    }
    return _accessToken!;
  }
}
