class CreditCard {
  final int id;
  final String name;
  final String company;
  final int annualFee;
  final String? imageUrl;
  final List<CardBenefit> benefits;

  CreditCard({
    required this.id,
    required this.name,
    required this.company,
    required this.annualFee,
    this.imageUrl,
    this.benefits = const [],
  });

  factory CreditCard.fromJson(Map<String, dynamic> json) {
    return CreditCard(
      id: json['id'],
      name: json['name'],
      company: json['company'],
      annualFee: json['annual_fee'],
      imageUrl: json['image_url'],
      benefits: (json['benefits'] as List?)
              ?.map((b) => CardBenefit.fromJson(b))
              .toList() ??
          [],
    );
  }
}

class CardBenefit {
  final int id;
  final String category;
  final String description;
  final double discountRate;
  final int? maxDiscount;

  CardBenefit({
    required this.id,
    required this.category,
    required this.description,
    required this.discountRate,
    this.maxDiscount,
  });

  factory CardBenefit.fromJson(Map<String, dynamic> json) {
    return CardBenefit(
      id: json['id'],
      category: json['category'],
      description: json['description'],
      discountRate: (json['discount_rate'] as num).toDouble(),
      maxDiscount: json['max_discount'],
    );
  }
}

class UserCard {
  final int id;
  final CreditCard card;
  final double totalBenefitReceived;
  final double totalSpent;
  final double benefitRate;

  UserCard({
    required this.id,
    required this.card,
    required this.totalBenefitReceived,
    required this.totalSpent,
    required this.benefitRate,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['id'],
      card: CreditCard.fromJson(json['card']),
      totalBenefitReceived: (json['total_benefit_received'] as num).toDouble(),
      totalSpent: (json['total_spent'] as num).toDouble(),
      benefitRate: (json['benefit_rate'] as num).toDouble(),
    );
  }

  double get roi {
    final monthlyAnnualFee = card.annualFee / 12;
    return totalBenefitReceived - monthlyAnnualFee;
  }
}
