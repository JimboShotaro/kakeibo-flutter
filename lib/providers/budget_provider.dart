import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../services/database_helper.dart';

class BudgetProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<Budget> _budgets = [];
  Budget? _overallBudget;
  bool _isLoading = false;
  
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  List<Budget> get budgets => _budgets;
  Budget? get overallBudget => _overallBudget;
  double get overallBudgetAmount => _overallBudget?.amountLimit ?? 0.0;
  bool get isLoading => _isLoading;
  int get selectedYear => _selectedYear;
  int get selectedMonth => _selectedMonth;

  /// 選択月を変更
  void setSelectedMonth(int year, int month) {
    _selectedYear = year;
    _selectedMonth = month;
    loadBudgets();
  }

  /// 予算データを読み込み
  Future<void> loadBudgets() async {
    _isLoading = true;
    notifyListeners();

    try {
      _budgets = await _dbHelper.getBudgets(year: _selectedYear, month: _selectedMonth);
      _overallBudget = await _dbHelper.getOverallBudget(_selectedYear, _selectedMonth);
    } catch (e) {
      debugPrint('予算データの読み込みに失敗: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 全体予算を設定
  Future<void> setOverallBudget(double amount) async {
    const uuid = Uuid();
    final budget = Budget(
      id: _overallBudget?.id ?? uuid.v4(),
      categoryId: null,
      amountLimit: amount,
      year: _selectedYear,
      month: _selectedMonth,
    );

    await _dbHelper.upsertBudget(budget);
    await loadBudgets();
  }

  /// カテゴリ別予算を設定
  Future<void> setCategoryBudget(String categoryId, double amount) async {
    const uuid = Uuid();
    
    // 既存の予算を探す
    Budget? existing;
    try {
      existing = _budgets.firstWhere(
        (b) => b.categoryId == categoryId,
      );
    } catch (e) {
      existing = null;
    }

    final budget = Budget(
      id: existing?.id ?? uuid.v4(),
      categoryId: categoryId,
      amountLimit: amount,
      year: _selectedYear,
      month: _selectedMonth,
    );

    await _dbHelper.upsertBudget(budget);
    await loadBudgets();
  }

  /// カテゴリ別予算を取得
  double getCategoryBudget(String categoryId) {
    try {
      final budget = _budgets.firstWhere(
        (b) => b.categoryId == categoryId,
      );
      return budget.amountLimit;
    } catch (e) {
      return 0.0;
    }
  }

  /// 予算を削除
  Future<void> deleteBudget(String id) async {
    await _dbHelper.deleteBudget(id);
    await loadBudgets();
  }
}
