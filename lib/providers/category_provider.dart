import 'package:flutter/foundation.dart';
import '../models/category.dart';
import '../services/database_helper.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  List<AppCategory> _categories = [];
  List<AppCategory> _expenseCategories = [];
  List<AppCategory> _incomeCategories = [];
  bool _isLoading = false;

  List<AppCategory> get categories => _categories;
  List<AppCategory> get expenseCategories => _expenseCategories;
  List<AppCategory> get incomeCategories => _incomeCategories;
  bool get isLoading => _isLoading;

  /// 全カテゴリを読み込み
  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _dbHelper.getCategories();
      _expenseCategories = await _dbHelper.getCategories(isExpense: true);
      _incomeCategories = await _dbHelper.getCategories(isExpense: false);
    } catch (e) {
      debugPrint('カテゴリの読み込みに失敗: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// IDからカテゴリを取得
  AppCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// カテゴリを追加
  Future<void> addCategory(AppCategory category) async {
    await _dbHelper.insertCategory(category);
    await loadCategories();
  }

  /// カテゴリを更新
  Future<void> updateCategory(AppCategory category) async {
    await _dbHelper.updateCategory(category);
    await loadCategories();
  }

  /// カテゴリを削除
  Future<void> deleteCategory(String id) async {
    await _dbHelper.deleteCategory(id);
    await loadCategories();
  }
}
