/// Budget model for tracking spending limits per category
class Budget {
  final String id;
  final String categoryId;
  final double limit; // Monthly budget limit
  final DateTime createdAt;
  final DateTime? lastModified;

  Budget({
    required this.id,
    required this.categoryId,
    required this.limit,
    required this.createdAt,
    this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'limit': limit,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
    };
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      limit: (json['limit'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
    );
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    double? limit,
    DateTime? createdAt,
    DateTime? lastModified,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      limit: limit ?? this.limit,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
