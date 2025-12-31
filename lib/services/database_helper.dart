import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../models/transaction.dart' as app;
import '../models/budget.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kakeibo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // カテゴリテーブル
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_expense INTEGER NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // トランザクションテーブル
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        transaction_date TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // 予算テーブル
    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        amount_limit REAL NOT NULL,
        period_type TEXT NOT NULL DEFAULT 'MONTHLY',
        year INTEGER NOT NULL,
        month INTEGER NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // インデックス
    await db.execute(
        'CREATE INDEX idx_transactions_date ON transactions (transaction_date)');
    await db.execute(
        'CREATE INDEX idx_transactions_category ON transactions (category_id)');
    await db.execute(
        'CREATE INDEX idx_budgets_period ON budgets (year, month)');

    // デフォルトカテゴリを挿入
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultCategories(Database db) async {
    const uuid = Uuid();

    // 支出カテゴリ
    final expenseCategories = [
      {'name': '食費', 'icon': 'restaurant', 'color': '#FF5722'},
      {'name': '交通費', 'icon': 'directions_car', 'color': '#2196F3'},
      {'name': '日用品', 'icon': 'shopping_cart', 'color': '#4CAF50'},
      {'name': '娯楽', 'icon': 'sports_esports', 'color': '#9C27B0'},
      {'name': '医療', 'icon': 'local_hospital', 'color': '#F44336'},
      {'name': '通信費', 'icon': 'phone', 'color': '#00BCD4'},
      {'name': '光熱費', 'icon': 'bolt', 'color': '#FFC107'},
      {'name': 'その他', 'icon': 'more_horiz', 'color': '#607D8B'},
    ];

    // 収入カテゴリ
    final incomeCategories = [
      {'name': '給料', 'icon': 'account_balance_wallet', 'color': '#4CAF50'},
      {'name': '副収入', 'icon': 'attach_money', 'color': '#8BC34A'},
      {'name': 'その他収入', 'icon': 'more_horiz', 'color': '#607D8B'},
    ];

    int sortOrder = 0;
    for (final cat in expenseCategories) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'is_expense': 1,
        'sort_order': sortOrder++,
      });
    }

    for (final cat in incomeCategories) {
      await db.insert('categories', {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon': cat['icon'],
        'color': cat['color'],
        'is_expense': 0,
        'sort_order': sortOrder++,
      });
    }
  }

  // ==================== カテゴリ CRUD ====================

  Future<List<AppCategory>> getCategories({bool? isExpense}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (isExpense != null) {
      where = 'is_expense = ?';
      whereArgs = [isExpense ? 1 : 0];
    }

    final result = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sort_order ASC',
    );

    return result.map((map) => AppCategory.fromMap(map)).toList();
  }

  Future<AppCategory?> getCategory(String id) async {
    final db = await database;
    final result = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;
    return AppCategory.fromMap(result.first);
  }

  Future<void> insertCategory(AppCategory category) async {
    final db = await database;
    await db.insert('categories', category.toMap());
  }

  Future<void> updateCategory(AppCategory category) async {
    final db = await database;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== トランザクション CRUD ====================

  Future<List<app.Transaction>> getTransactions({
    String? startDate,
    String? endDate,
    String? categoryId,
  }) async {
    final db = await database;
    String where = '1=1';
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      where += ' AND transaction_date >= ?';
      whereArgs.add(startDate);
    }
    if (endDate != null) {
      where += ' AND transaction_date <= ?';
      whereArgs.add(endDate);
    }
    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }

    final result = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'transaction_date DESC, created_at DESC',
    );

    return result.map((map) => app.Transaction.fromMap(map)).toList();
  }

  Future<List<app.Transaction>> getTransactionsByMonth(int year, int month) async {
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'transaction_date >= ? AND transaction_date < ?',
      whereArgs: [startDate, endDate],
      orderBy: 'transaction_date DESC, created_at DESC',
    );

    return result.map((map) => app.Transaction.fromMap(map)).toList();
  }

  Future<void> insertTransaction(app.Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  Future<void> updateTransaction(app.Transaction transaction) async {
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 予算 CRUD ====================

  Future<List<Budget>> getBudgets({int? year, int? month}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (year != null && month != null) {
      where = 'year = ? AND month = ?';
      whereArgs = [year, month];
    }

    final result = await db.query(
      'budgets',
      where: where,
      whereArgs: whereArgs,
    );

    return result.map((map) => Budget.fromMap(map)).toList();
  }

  Future<Budget?> getOverallBudget(int year, int month) async {
    final db = await database;
    final result = await db.query(
      'budgets',
      where: 'year = ? AND month = ? AND category_id IS NULL',
      whereArgs: [year, month],
    );

    if (result.isEmpty) return null;
    return Budget.fromMap(result.first);
  }

  Future<void> insertBudget(Budget budget) async {
    final db = await database;
    await db.insert('budgets', budget.toMap());
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> upsertBudget(Budget budget) async {
    final db = await database;
    
    // 既存の予算を確認
    String where;
    List<dynamic> whereArgs;
    
    if (budget.categoryId == null) {
      where = 'year = ? AND month = ? AND category_id IS NULL';
      whereArgs = [budget.year, budget.month];
    } else {
      where = 'year = ? AND month = ? AND category_id = ?';
      whereArgs = [budget.year, budget.month, budget.categoryId];
    }
    
    final existing = await db.query('budgets', where: where, whereArgs: whereArgs);
    
    if (existing.isEmpty) {
      await db.insert('budgets', budget.toMap());
    } else {
      await db.update(
        'budgets',
        budget.toMap(),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    }
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== 集計クエリ ====================

  Future<double> getTotalExpenseByMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
        AND c.is_expense = 1
    ''', [startDate, endDate]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalIncomeByMonth(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
        AND c.is_expense = 0
    ''', [startDate, endDate]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getExpenseByCategory(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT c.id, c.name, COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
        AND c.is_expense = 1
      GROUP BY c.id, c.name
      ORDER BY total DESC
    ''', [startDate, endDate]);

    Map<String, double> categoryTotals = {};
    for (final row in result) {
      categoryTotals[row['id'] as String] = (row['total'] as num).toDouble();
    }
    return categoryTotals;
  }

  Future<Map<String, double>> getDailyExpense(int year, int month) async {
    final db = await database;
    final startDate = '$year-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final endDate = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    final result = await db.rawQuery('''
      SELECT t.transaction_date, COALESCE(SUM(t.amount), 0) as total
      FROM transactions t
      INNER JOIN categories c ON t.category_id = c.id
      WHERE t.transaction_date >= ? AND t.transaction_date < ?
        AND c.is_expense = 1
      GROUP BY t.transaction_date
      ORDER BY t.transaction_date ASC
    ''', [startDate, endDate]);

    Map<String, double> dailyTotals = {};
    for (final row in result) {
      dailyTotals[row['transaction_date'] as String] =
          (row['total'] as num).toDouble();
    }
    return dailyTotals;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
