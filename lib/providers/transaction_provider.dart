import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart' as app;
import '../services/database_helper.dart';
import '../services/analysis_service.dart';

class TransactionProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final AnalysisService _analysisService = AnalysisService();
  
  List<app.Transaction> _transactions = [];
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  Map<String, double> _expenseByCategory = {};
  Map<String, double> _dailyExpense = {};
  bool _isLoading = false;
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<app.Transaction> get transactions => _transactions;
  double get totalExpense => _totalExpense;
  double get totalIncome => _totalIncome;
  double get balance => _totalIncome - _totalExpense;
  Map<String, double> get expenseByCategory => _expenseByCategory;
  Map<String, double> get dailyExpense => _dailyExpense;
  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  /// 月末予測支出を計算
  double get forecastExpense {
    final daysInMonth = _analysisService.getDaysInMonth(_selectedYear, _selectedMonth);
    final daysElapsed = _analysisService.getDaysElapsed(_selectedYear, _selectedMonth);
    
    return _analysisService.predictMonthlyTotal(
      currentTotal: _totalExpense,
      daysElapsed: daysElapsed,
      daysInMonth: daysInMonth,
    );
  }

  /// 選択月を変更
  void setSelectedMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    loadTransactions();
  }

  /// 前月へ
  void previousMonth() {
    if (_selectedMonth == 1) {
      _selectedYear--;
      _selectedMonth = 12;
    } else {
      _selectedMonth--;
    }
    loadTransactions();
  }

  /// 次月へ
  void nextMonth() {
    if (_selectedMonth == 12) {
      _selectedYear++;
      _selectedMonth = 1;
    } else {
      _selectedMonth++;
    }
    loadTransactions();
  }

  /// 取引データを読み込み
  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _transactions = await _dbHelper.getTransactionsByMonth(_selectedYear, _selectedMonth);
      _totalExpense = await _dbHelper.getTotalExpenseByMonth(_selectedYear, _selectedMonth);
      _totalIncome = await _dbHelper.getTotalIncomeByMonth(_selectedYear, _selectedMonth);
      _expenseByCategory = await _dbHelper.getExpenseByCategory(_selectedYear, _selectedMonth);
      _dailyExpense = await _dbHelper.getDailyExpense(_selectedYear, _selectedMonth);
    } catch (e) {
      debugPrint('取引データの読み込みに失敗: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 取引を追加
  Future<void> addTransaction({
    required String categoryId,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    const uuid = Uuid();
    final now = DateTime.now().toIso8601String();
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    final transaction = app.Transaction(
      id: uuid.v4(),
      categoryId: categoryId,
      amount: amount,
      transactionDate: dateStr,
      note: note,
      createdAt: now,
      updatedAt: now,
    );

    await _dbHelper.insertTransaction(transaction);
    await loadTransactions();
  }

  /// 取引を更新
  Future<void> updateTransaction(app.Transaction transaction) async {
    final updated = transaction.copyWith(
      updatedAt: DateTime.now().toIso8601String(),
    );
    await _dbHelper.updateTransaction(updated);
    await loadTransactions();
  }

  /// 取引を削除
  Future<void> deleteTransaction(String id) async {
    await _dbHelper.deleteTransaction(id);
    await loadTransactions();
  }

  /// 日付でグループ化した取引を取得
  Map<String, List<app.Transaction>> get transactionsByDate {
    Map<String, List<app.Transaction>> grouped = {};
    for (final tx in _transactions) {
      if (!grouped.containsKey(tx.transactionDate)) {
        grouped[tx.transactionDate] = [];
      }
      grouped[tx.transactionDate]!.add(tx);
    }
    return grouped;
  }

  /// カテゴリ別支出を金額順で取得
  List<MapEntry<String, double>> get sortedExpenseByCategory {
    final entries = _expenseByCategory.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
