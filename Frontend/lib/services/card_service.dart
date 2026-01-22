// lib/services/card_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/user_card.dart';
import 'package:my_app/services/api_service.dart';

class CardService {
  static const String baseUrl = ApiService.baseUrl;

  // Helper to get headers with token
  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // 내 카드 목록 조회
  Future<List<UserCard>> getMyCards() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/cards/'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['cards'] as List)
          .map((card) => UserCard.fromJson(card))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
    } else {
      throw Exception('카드 목록 조회 실패: ${response.statusCode}');
    }
  }
}
