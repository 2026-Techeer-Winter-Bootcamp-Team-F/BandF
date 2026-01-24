// lib/services/card_service.dart
// [설명] 백엔드 카드 API와 통신하는 서비스 클래스
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_app/models/card.dart';
import 'package:my_app/services/api_service.dart';

class CardService {
  static final String baseUrl = ApiService.baseUrl;

  // [설명] 인증 토큰을 포함한 HTTP 헤더 생성 헬퍼 메서드
  // [용도] API 요청 시 JWT 토큰을 Authorization 헤더에 포함
  Future<Map<String, String>> get _headers async {
    final token = await ApiService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // [설명] 사용자가 등록한 카드 목록 조회
  // [API 엔드포인트] GET /api/v1/cards/
  // [백엔드 응답 형식]
  // {
  //   "message": "내 카드 목록 조회 성공",
  //   "cards": [
  //     {
  //       "card_id": 1,
  //       "card_name": "신한Deep Dream 카드",
  //       "card_image_url": "https://...",  // 백엔드 DB에 저장된 이미지 URL
  //       "company": "신한카드",
  //       "card_number": "**** 1234"
  //     }
  //   ]
  // }
  Future<List<CreditCard>> getMyCards() async {
    final headers = await _headers;
    // [설명] 백엔드 카드 목록 API 호출
    final response = await http.get(
      Uri.parse('$baseUrl/cards/'),
      headers: headers,
    );

    print('[CardService] getMyCards 응답: ${response.statusCode}');
    print('[CardService] 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        // [설명] 응답의 'cards' 배열을 CreditCard 객체 리스트로 변환
        // 각 카드 객체에는 백엔드에서 제공하는 이미지 URL이 포함됨
        return (data['cards'] as List)
            .map((card) => CreditCard.fromJson(card))
            .toList();
      } catch (e) {
        print('[CardService] JSON 파싱 에러: $e');
        throw Exception('카드 데이터 파싱 실패: $e');
      }
    } else if (response.statusCode == 401) {
      // [설명] 인증 실패 시 에러 처리
      throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
    } else {
      // [설명] 기타 에러 처리
      throw Exception('카드 목록 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

  // [설명] 추천 카드 목록 조회 (사용자 소비 패턴 기반)
  // [API 엔드포인트] GET /api/v1/cards/recommend/
  // [백엔드 응답] 최근 3개월 소비가 많은 카테고리에 혜택이 높은 카드 반환
  Future<List<CreditCard>> getRecommendedCards() async {
    final headers = await _headers;
    final response = await http.get(
      Uri.parse('$baseUrl/cards/recommend/'),
      headers: headers,
    );

    print('[CardService] getRecommendedCards 응답: ${response.statusCode}');
    print('[CardService] 응답 본문: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        // [설명] 추천 카드 리스트 파싱 (각 카드에 이미지 URL 포함)
        return (data['recommended_cards'] as List)
            .map((card) => CreditCard.fromJson(card))
            .toList();
      } catch (e) {
        print('[CardService] JSON 파싱 에러: $e');
        throw Exception('추천 카드 데이터 파싱 실패: $e');
      }
    } else if (response.statusCode == 401) {
      throw Exception('인증이 필요합니다. 다시 로그인해주세요.');
    } else if (response.statusCode == 404) {
      // [수정] 지출 데이터가 없으면 빈 리스트 반환 (에러 대신)
      print('[CardService] 지출 데이터가 없어서 추천 카드가 없습니다.');
      return [];
    } else {
      throw Exception('추천 카드 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }
}
