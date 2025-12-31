import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/settings_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../models/app_settings.dart';
import '../services/backup_service.dart';
import 'category_screen.dart';
import 'budget_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 背景設定
              _buildSectionTitle(context, '背景設定'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<BackgroundType>(
                      title: const Text('単色'),
                      value: BackgroundType.color,
                      groupValue: settings.backgroundType,
                      onChanged: (value) {
                        if (value != null) {
                          _showColorPicker(context, settingsProvider);
                        }
                      },
                    ),
                    RadioListTile<BackgroundType>(
                      title: const Text('グラデーション'),
                      value: BackgroundType.gradient,
                      groupValue: settings.backgroundType,
                      onChanged: (value) {
                        if (value != null) {
                          _showGradientPicker(context, settingsProvider);
                        }
                      },
                    ),
                    RadioListTile<BackgroundType>(
                      title: const Text('画像'),
                      value: BackgroundType.image,
                      groupValue: settings.backgroundType,
                      onChanged: (value) {
                        if (value != null) {
                          _pickImage(context, settingsProvider);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // プレビュー
              _buildSectionTitle(context, '背景プレビュー'),
              Container(
                height: 150,
                decoration: settingsProvider.getBackgroundDecoration()?.copyWith(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'プレビュー',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // テーマ設定
              _buildSectionTitle(context, 'テーマ'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('ライト'),
                      secondary: const Icon(Icons.light_mode),
                      value: 'light',
                      groupValue: settings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('ダーク'),
                      secondary: const Icon(Icons.dark_mode),
                      value: 'dark',
                      groupValue: settings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('システム設定に従う'),
                      secondary: const Icon(Icons.settings_suggest),
                      value: 'system',
                      groupValue: settings.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          settingsProvider.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 表示設定
              _buildSectionTitle(context, '表示設定'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('予算残額を表示'),
                      subtitle: const Text('ホーム画面に残額を大きく表示'),
                      value: settings.showBudgetRemaining,
                      onChanged: (value) {
                        settingsProvider.setShowBudgetRemaining(value);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('カレンダーデフォルト表示'),
                      trailing: DropdownButton<CalendarViewMode>(
                        value: settings.calendarDefaultView,
                        onChanged: (value) {
                          if (value != null) {
                            settingsProvider.setCalendarDefaultView(value);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: CalendarViewMode.month,
                            child: Text('月表示'),
                          ),
                          DropdownMenuItem(
                            value: CalendarViewMode.week,
                            child: Text('週表示'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // データバックアップ
              _buildSectionTitle(context, 'データ管理'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: const Text('データをバックアップ'),
                      subtitle: const Text('JSONファイルにエクスポート'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showBackupDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('データを復元'),
                      subtitle: const Text('バックアップファイルから復元'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showRestoreDialog(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('カテゴリ管理'),
                      subtitle: const Text('カテゴリの追加・編集・削除'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoryScreen()),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.account_balance_wallet),
                      title: const Text('予算設定'),
                      subtitle: const Text('月間予算・カテゴリ別予算'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BudgetScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // アプリについて
              _buildSectionTitle(context, 'その他'),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('アプリについて'),
                  subtitle: const Text('バージョン 2.1.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: '家計簿',
                      applicationVersion: '2.1.0',
                      applicationLegalese: '© 2024 Smart Ledger',
                      children: const [
                        SizedBox(height: 16),
                        Text('シンプルで使いやすい家計簿アプリです。'),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データバックアップ'),
        content: const Text(
          'データをJSONファイルにエクスポートします。\n'
          'ファイルを共有して保存することができます。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('共有'),
            onPressed: () async {
              Navigator.pop(context);
              await _performBackup(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(BuildContext context) async {
    final backupService = BackupService();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await backupService.shareBackup();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('バックアップファイルを作成しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('バックアップに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データ復元'),
        content: const Text(
          '⚠️ 注意: 復元を行うと、現在のデータは全て上書きされます。\n\n'
          'バックアップファイル（.json）を選択してください。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('ファイルを選択'),
            onPressed: () async {
              Navigator.pop(context);
              await _performRestore(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final backupService = BackupService();

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final restoreResult = await backupService.importFromJson(file);

      if (context.mounted) {
        Navigator.pop(context);

        if (restoreResult.success) {
          // プロバイダーをリロード
          final categoryProvider = context.read<CategoryProvider>();
          final transactionProvider = context.read<TransactionProvider>();
          final budgetProvider = context.read<BudgetProvider>();
          
          await categoryProvider.loadCategories();
          await transactionProvider.loadTransactions();
          await budgetProvider.loadBudgets();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(restoreResult.message),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(restoreResult.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('復元に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, SettingsProvider provider) {
    final colors = [
      '#F5F5F5', '#E3F2FD', '#E8F5E9', '#FFF3E0', '#FCE4EC',
      '#F3E5F5', '#E0F7FA', '#FFF8E1', '#EFEBE9', '#ECEFF1',
      '#2196F3', '#4CAF50', '#FF9800', '#E91E63', '#9C27B0',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '背景色を選択',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((colorHex) {
                final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () {
                    provider.setBackgroundColor(colorHex);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showGradientPicker(BuildContext context, SettingsProvider provider) {
    final gradients = [
      ['#667eea', '#764ba2'],
      ['#f093fb', '#f5576c'],
      ['#4facfe', '#00f2fe'],
      ['#43e97b', '#38f9d7'],
      ['#fa709a', '#fee140'],
      ['#a8edea', '#fed6e3'],
      ['#d299c2', '#fef9d7'],
      ['#89f7fe', '#66a6ff'],
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'グラデーションを選択',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: gradients.map((colors) {
                final startColor = Color(int.parse(colors[0].replaceFirst('#', '0xFF')));
                final endColor = Color(int.parse(colors[1].replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () {
                    provider.setBackgroundGradient(colors[0], colors[1]);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [startColor, endColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, SettingsProvider provider) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await provider.setBackgroundImage(File(image.path));
    }
  }
}
