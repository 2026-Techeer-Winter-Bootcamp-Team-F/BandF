// lib/models/user_card.dart
class UserCard {
  final int cardId;
  final String cardName;
  final String cardNumber;
  final String cardImageUrl;
  final String company;
  final String cardType;

  UserCard({
    required this.cardId,
    required this.cardName,
    required this.cardNumber,
    required this.cardImageUrl,
    required this.company,
    this.cardType = '',
  });

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      cardId: json['card_id'] as int,
      cardName: json['card_name'] as String,
      cardNumber: json['card_number'] as String? ?? '',
      cardImageUrl: json['card_image_url'] as String,
      company: json['company'] as String,
      cardType: json['card_type'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'card_name': cardName,
      'card_number': cardNumber,
      'card_image_url': cardImageUrl,
      'company': company,
      'card_type': cardType,
    };
  }

  // UI용 마스킹된 카드번호 표시
  String get displayCardNumber {
    if (cardNumber.isEmpty) return '';
    return cardNumber;
  }
}
