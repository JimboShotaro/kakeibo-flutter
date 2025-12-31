import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart' as app;
import '../models/category.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';

class TransactionFormScreen extends StatefulWidget {
  final app.Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isExpense = true;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _amountController.text = widget.transaction!.amount.toStringAsFixed(0);
      _noteController.text = widget.transaction!.note;
      _selectedCategoryId = widget.transaction!.categoryId;
      _selectedDate = widget.transaction!.date;
      
      // カテゴリから収入/支出を判定
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final categoryProvider = context.read<CategoryProvider>();
        final category = categoryProvider.getCategoryById(widget.transaction!.categoryId);
        if (category != null) {
          setState(() {
            _isExpense = category.isExpense;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final categories = _isExpense 
        ? categoryProvider.expenseCategories 
        : categoryProvider.incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '取引を編集' : '取引を追加'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTransaction,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 支出/収入切り替え
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        label: '支出',
                        isSelected: _isExpense,
                        color: AppTheme.expenseColor,
                        onTap: () {
                          setState(() {
                            _isExpense = true;
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeButton(
                        label: '収入',
                        isSelected: !_isExpense,
                        color: AppTheme.incomeColor,
                        onTap: () {
                          setState(() {
                            _isExpense = false;
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 金額入力
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '金額',
                prefixText: '¥ ',
                prefixIcon: Icon(
                  _isExpense ? Icons.remove : Icons.add,
                  color: _isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: Theme.of(context).textTheme.headlineSmall,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '金額を入力してください';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '正しい金額を入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 日付選択
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('日付'),
              trailing: Text(
                Formatters.formatDate(_selectedDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              onTap: _selectDate,
            ),
            const Divider(),

            // カテゴリ選択
            const SizedBox(height: 8),
            Text(
              'カテゴリ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildCategoryGrid(categories),
            const SizedBox(height: 16),

            // メモ入力
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // 保存ボタン
            FilledButton(
              onPressed: _isLoading ? null : _saveTransaction,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? '更新' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<AppCategory> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategoryId == category.id;

        return Material(
          color: isSelected ? category.colorValue.withAlpha(51) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedCategoryId = category.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? category.colorValue : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: category.colorValue.withAlpha(51),
                    child: Icon(
                      category.iconData,
                      color: category.colorValue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('カテゴリを選択してください')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final txProvider = context.read<TransactionProvider>();
      final amount = double.parse(_amountController.text);

      if (isEditing) {
        await txProvider.updateTransaction(
          widget.transaction!.copyWith(
            categoryId: _selectedCategoryId,
            amount: amount,
            transactionDate: '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
            note: _noteController.text,
          ),
        );
      } else {
        await txProvider.addTransaction(
          categoryId: _selectedCategoryId!,
          amount: amount,
          date: _selectedDate,
          note: _noteController.text,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? '取引を更新しました' : '取引を追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTransaction() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この取引を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final txProvider = context.read<TransactionProvider>();
      await txProvider.deleteTransaction(widget.transaction!.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('取引を削除しました')),
        );
      }
    }
  }
}
