class Budget {
  final String id;
  final String? categoryId; // Nullなら全体予算
  final double amountLimit;
  final String periodType; // MONTHLY
  final int year;
  final int month;

  Budget({
    required this.id,
    this.categoryId,
    required this.amountLimit,
    this.periodType = 'MONTHLY',
    required this.year,
    required this.month,
  });

  /// 全体予算かどうか
  bool get isOverallBudget => categoryId == null;

  /// データベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount_limit': amountLimit,
      'period_type': periodType,
      'year': year,
      'month': month,
    };
  }

  /// MapからBudgetを生成
  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      amountLimit: (map['amount_limit'] as num).toDouble(),
      periodType: map['period_type'] as String? ?? 'MONTHLY',
      year: map['year'] as int,
      month: map['month'] as int,
    );
  }

  /// コピーを作成
  Budget copyWith({
    String? id,
    String? categoryId,
    double? amountLimit,
    String? periodType,
    int? year,
    int? month,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      periodType: periodType ?? this.periodType,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}
