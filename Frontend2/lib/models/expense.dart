class Expense {
  final int id;
  final String merchant;
  final int amount;
  final String category;
  final DateTime date;
  final int? cardId;
  final double? benefitAmount;

  Expense({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.date,
    this.cardId,
    this.benefitAmount,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      merchant: json['merchant'],
      amount: json['amount'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      cardId: json['card_id'],
      benefitAmount: json['benefit_amount']?.toDouble(),
    );
  }
}

class ExpenseSummary {
  final int totalAmount;
  final Map<String, int> byCategory;
  final Map<String, int> byCard;
  final int totalBenefit;

  ExpenseSummary({
    required this.totalAmount,
    required this.byCategory,
    required this.byCard,
    required this.totalBenefit,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      totalAmount: json['total_amount'],
      byCategory: Map<String, int>.from(json['by_category']),
      byCard: Map<String, int>.from(json['by_card']),
      totalBenefit: json['total_benefit'],
    );
  }
}

class CategoryExpense {
  final String category;
  final int amount;
  final double percentage;

  CategoryExpense({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}
