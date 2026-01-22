import 'package:flutter/material.dart';

class AccumulatedData {
  final int total;
  final List<DailyData> dailyData;

  AccumulatedData({required this.total, required this.dailyData});

  factory AccumulatedData.fromJson(Map<String, dynamic> json) {
    var list = json['daily_data'] as List? ?? [];
    List<DailyData> dailyDataList = list
        .map((i) => DailyData.fromJson(i))
        .toList();
    return AccumulatedData(total: json['total'] ?? 0, dailyData: dailyDataList);
  }
}

class DailyData {
  final String date;
  final double amount;

  DailyData({required this.date, required this.amount});

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class DailySummary {
  final Map<int, int> expenses;

  DailySummary({required this.expenses});

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    Map<int, int> expensesMap = {};
    if (json['expenses'] != null) {
      (json['expenses'] as Map).forEach((k, v) {
        expensesMap[int.parse(k.toString())] = v as int;
      });
    }
    return DailySummary(expenses: expensesMap);
  }
}

class WeeklyData {
  final int average;

  WeeklyData({required this.average});

  factory WeeklyData.fromJson(Map<String, dynamic> json) {
    return WeeklyData(average: json['average'] ?? 0);
  }
}

class MonthlyData {
  final int average;

  MonthlyData({required this.average});

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(average: json['average'] ?? 0);
  }
}

class CategoryData {
  final String name;
  final int amount;
  final int change;
  final int percent;
  final String emoji;
  final Color color;

  CategoryData({
    required this.name,
    required this.amount,
    required this.change,
    required this.percent,
    required this.emoji,
    required this.color,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      name: json['name'] ?? '',
      amount: json['amount'] ?? 0,
      change: json['change'] ?? 0,
      percent: json['percent'] ?? 0,
      emoji: json['emoji'] ?? '❓',
      color: _parseColor(json['color']),
    );
  }

  static Color _parseColor(dynamic colorData) {
    if (colorData is String) {
      if (colorData.startsWith('#')) {
        return Color(int.parse(colorData.replaceFirst('#', '0xff')));
      }
    }
    return Colors.grey;
  }
}

class MonthComparison {
  final int lastMonthSameDay;
  final List<DailyData> lastMonthData;

  MonthComparison({
    required this.lastMonthSameDay,
    required this.lastMonthData,
  });

  factory MonthComparison.fromJson(Map<String, dynamic> json) {
    var list = json['last_month_data'] as List? ?? [];
    List<DailyData> lastList = list.map((i) => DailyData.fromJson(i)).toList();
    return MonthComparison(
      lastMonthSameDay: json['last_month_same_day'] ?? 0,
      lastMonthData: lastList,
    );
  }
}

class Transaction {
  final String name;
  final int amount;
  final String? currency;
  final IconData icon;
  final Color color;

  Transaction({
    required this.name,
    required this.amount,
    this.currency,
    required this.icon,
    required this.color,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      name: json['name'] ?? 'Unknown',
      amount: json['amount'] ?? 0,
      currency: json['currency'],
      icon: Icons.credit_card, // Default icon
      color: Colors.blue, // Default color
    );
  }
}
