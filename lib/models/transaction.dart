class Transaction {
  final String id;
  final String categoryId;
  final double amount;
  final String transactionDate; // YYYY-MM-DD
  final String note;
  final String createdAt;
  final String updatedAt;

  Transaction({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.transactionDate,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 日付をDateTimeとして取得
  DateTime get date => DateTime.parse(transactionDate);

  /// データベース用のMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount': amount,
      'transaction_date': transactionDate,
      'note': note,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  /// MapからTransactionを生成
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      transactionDate: map['transaction_date'] as String,
      note: map['note'] as String? ?? '',
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  /// コピーを作成
  Transaction copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? transactionDate,
    String? note,
    String? createdAt,
    String? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      transactionDate: transactionDate ?? this.transactionDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
