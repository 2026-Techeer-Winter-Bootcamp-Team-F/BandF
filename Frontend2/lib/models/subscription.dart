enum SubscriptionStatus { active, canceled }

class Subscription {
  final int id;
  final String name;
  final int amount;
  final String cycle;
  final SubscriptionStatus status;
  final double? utilityScore;
  final String? category;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.cycle,
    required this.status,
    this.utilityScore,
    this.category,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'],
      name: json['name'],
      amount: json['amount'],
      cycle: json['cycle'],
      status: json['status'] == 'active'
          ? SubscriptionStatus.active
          : SubscriptionStatus.canceled,
      utilityScore: json['utility_score']?.toDouble(),
      category: json['category'],
    );
  }

  bool get isLowUtility => utilityScore != null && utilityScore! < 3.0;
}
