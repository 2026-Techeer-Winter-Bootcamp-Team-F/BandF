// lib/models/home_data.dart
import 'package:flutter/material.dart';

class AccumulatedData {
  final int total;
  final List<DailyAccumulated> dailyData;

  AccumulatedData({
    required this.total,
    required this.dailyData,
  });

  factory AccumulatedData.fromJson(Map<String, dynamic> json) {
    return AccumulatedData(
      total: json['total'] as int,
      dailyData: (json['dailyData'] as List)
          .map((e) => DailyAccumulated.fromJson(e))
          .toList(),
    );
  }
}

class DailyAccumulated {
  final int day;
  final double amount;

  DailyAccumulated({
    required this.day,
    required this.amount,
  });

  factory DailyAccumulated.fromJson(Map<String, dynamic> json) {
    return DailyAccumulated(
      day: json['day'] as int,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

class DailySummary {
  final Map<int, int> expenses;

  DailySummary({required this.expenses});

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    final Map<int, int> expenseMap = {};
    (json['expenses'] as Map<String, dynamic>).forEach((key, value) {
      expenseMap[int.parse(key)] = value as int;
    });
    return DailySummary(expenses: expenseMap);
  }
}

class Transaction {
  final String name;
  final String category;
  final int amount;
  final String? currency;

  Transaction({
    required this.name,
    required this.category,
    required this.amount,
    this.currency,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      name: json['name'] as String,
      category: json['category'] as String,
      amount: json['amount'] as int,
      currency: json['currency'] as String?,
    );
  }

  // UI용 아이콘 매핑
  IconData get icon {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      case 'cafe':
        return Icons.coffee;
      case 'transport':
        return Icons.directions_bus;
      case 'money':
        return Icons.account_balance_wallet;
      case 'github':
        return Icons.code;
      default:
        return Icons.receipt;
    }
  }

  // UI용 색상 매핑
  Color get color {
    switch (category.toLowerCase()) {
      case 'shopping':
        return Colors.grey;
      case 'food':
        return Colors.orange;
      case 'cafe':
        return Colors.brown;
      case 'transport':
        return Colors.blue;
      case 'money':
        return Colors.blue;
      case 'github':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }
}

class WeeklyData {
  final int average;

  WeeklyData({required this.average});

  factory WeeklyData.fromJson(Map<String, dynamic> json) {
    return WeeklyData(average: json['average'] as int);
  }
}

class MonthlyData {
  final int average;

  MonthlyData({required this.average});

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(average: json['average'] as int);
  }
}

class CategoryData {
  final String name;
  final String emoji;
  final int amount;
  final int change;
  final int percent;
  final String colorHex;

  CategoryData({
    required this.name,
    required this.emoji,
    required this.amount,
    required this.change,
    required this.percent,
    required this.colorHex,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      amount: json['amount'] as int,
      change: json['change'] as int,
      percent: json['percent'] as int,
      colorHex: json['color'] as String,
    );
  }

  Color get color {
    return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  }
}

class MonthComparison {
  final int thisMonthTotal;
  final int lastMonthSameDay;
  final List<DailyAccumulated> thisMonthData;
  final List<DailyAccumulated> lastMonthData;

  MonthComparison({
    required this.thisMonthTotal,
    required this.lastMonthSameDay,
    required this.thisMonthData,
    required this.lastMonthData,
  });

  factory MonthComparison.fromJson(Map<String, dynamic> json) {
    return MonthComparison(
      thisMonthTotal: json['thisMonthTotal'] as int,
      lastMonthSameDay: json['lastMonthSameDay'] as int,
      thisMonthData: (json['thisMonthData'] as List)
          .map((e) => DailyAccumulated.fromJson(e))
          .toList(),
      lastMonthData: (json['lastMonthData'] as List)
          .map((e) => DailyAccumulated.fromJson(e))
          .toList(),
    );
  }
}
