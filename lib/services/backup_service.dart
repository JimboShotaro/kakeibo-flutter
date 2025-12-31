import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'database_helper.dart';

/// バックアップ/復元サービス
class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// バックアップデータを作成
  Future<Map<String, dynamic>> createBackupData() async {
    final db = await _dbHelper.database;

    // 各テーブルのデータを取得
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final budgets = await db.query('budgets');

    return {
      'version': '2.1.0',
      'createdAt': DateTime.now().toIso8601String(),
      'data': {
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
      },
    };
  }

  /// JSONファイルにエクスポート
  Future<File> exportToJson() async {
    final backupData = await createBackupData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final file = File('${directory.path}/kakeibo_backup_$timestamp.json');

    await file.writeAsString(jsonString);
    return file;
  }

  /// バックアップファイルを共有
  Future<void> shareBackup() async {
    final file = await exportToJson();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: '家計簿バックアップ',
      text: '家計簿アプリのバックアップデータです',
    );
  }

  /// JSONファイルからインポート
  Future<BackupResult> importFromJson(File file) async {
    try {
      final jsonString = await file.readAsString();
      final backupData = json.decode(jsonString) as Map<String, dynamic>;

      // バージョンチェック
      final version = backupData['version'] as String?;
      if (version == null) {
        return BackupResult(
          success: false,
          message: '無効なバックアップファイルです',
        );
      }

      final data = backupData['data'] as Map<String, dynamic>;
      final db = await _dbHelper.database;

      // トランザクションで復元
      await db.transaction((txn) async {
        // 既存データをクリア
        await txn.delete('transactions');
        await txn.delete('budgets');
        await txn.delete('categories');

        // カテゴリを復元
        final categories = data['categories'] as List<dynamic>;
        for (final category in categories) {
          await txn.insert('categories', Map<String, dynamic>.from(category));
        }

        // 取引を復元
        final transactions = data['transactions'] as List<dynamic>;
        for (final transaction in transactions) {
          await txn.insert('transactions', Map<String, dynamic>.from(transaction));
        }

        // 予算を復元
        final budgets = data['budgets'] as List<dynamic>;
        for (final budget in budgets) {
          await txn.insert('budgets', Map<String, dynamic>.from(budget));
        }
      });

      final categoriesCount = (data['categories'] as List).length;
      final transactionsCount = (data['transactions'] as List).length;
      final budgetsCount = (data['budgets'] as List).length;

      return BackupResult(
        success: true,
        message: '復元完了: カテゴリ$categoriesCount件、取引$transactionsCount件、予算$budgetsCount件',
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: '復元に失敗しました: $e',
      );
    }
  }

  /// バックアップファイル一覧を取得
  Future<List<FileSystemEntity>> getBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory
        .listSync()
        .where((file) =>
            file.path.contains('kakeibo_backup_') && file.path.endsWith('.json'))
        .toList();
    
    // 新しい順にソート
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// バックアップファイルを削除
  Future<void> deleteBackup(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// バックアップ結果
class BackupResult {
  final bool success;
  final String message;

  BackupResult({
    required this.success,
    required this.message,
  });
}
