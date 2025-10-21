import 'package:intl/intl.dart';

/// Represents a financial transaction from a bank account
class Transaction {
  final String id;
  final String plaidId;
  final String name;
  final double amount;
  final DateTime date;
  final String? merchantName;
  String? category;
  bool isCategorized;
  final String? institutionId; // Which bank this transaction came from
  final String? institutionName; // Bank display name

  Transaction({
    required this.id,
    required this.plaidId,
    required this.name,
    required this.amount,
    required this.date,
    this.merchantName,
    this.category,
    this.isCategorized = false,
    this.institutionId,
    this.institutionName,
  });

  /// Convert Transaction to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plaidId': plaidId,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'merchantName': merchantName,
      'category': category,
      'isCategorized': isCategorized,
      'institutionId': institutionId,
      'institutionName': institutionName,
    };
  }

  /// Create Transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      plaidId: json['plaidId'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      merchantName: json['merchantName'] as String?,
      category: json['category'] as String?,
      isCategorized: json['isCategorized'] as bool? ?? false,
      institutionId: json['institutionId'] as String?,
      institutionName: json['institutionName'] as String?,
    );
  }

  /// Get formatted date string
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  /// Get formatted amount string
  String get formattedAmount => '\$${amount.toStringAsFixed(2)}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction{id: $id, name: $name, amount: $amount, date: $date, category: $category}';
  }
}
