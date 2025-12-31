import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/month_selector.dart';
import '../widgets/budget_progress_bar.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BudgetProvider>().loadBudgets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予算設定'),
      ),
      body: Consumer3<BudgetProvider, TransactionProvider, CategoryProvider>(
        builder: (context, budgetProvider, txProvider, categoryProvider, child) {
          if (budgetProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月選択
                MonthSelector(
                  year: budgetProvider.selectedYear,
                  month: budgetProvider.selectedMonth,
                  onPrevious: () {
                    final newMonth = budgetProvider.selectedMonth == 1 ? 12 : budgetProvider.selectedMonth - 1;
                    final newYear = budgetProvider.selectedMonth == 1 ? budgetProvider.selectedYear - 1 : budgetProvider.selectedYear;
                    budgetProvider.setSelectedMonth(newYear, newMonth);
                    txProvider.setSelectedMonth(newYear, newMonth);
                  },
                  onNext: () {
                    final newMonth = budgetProvider.selectedMonth == 12 ? 1 : budgetProvider.selectedMonth + 1;
                    final newYear = budgetProvider.selectedMonth == 12 ? budgetProvider.selectedYear + 1 : budgetProvider.selectedYear;
                    budgetProvider.setSelectedMonth(newYear, newMonth);
                    txProvider.setSelectedMonth(newYear, newMonth);
                  },
                ),
                const SizedBox(height: 24),

                // 月間予算
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '月間予算',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () => _showBudgetDialog(
                                context,
                                '月間予算',
                                budgetProvider.overallBudgetAmount,
                                (amount) => budgetProvider.setOverallBudget(amount),
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('編集'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.formatCurrency(budgetProvider.overallBudgetAmount),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                        if (budgetProvider.overallBudgetAmount > 0) ...[
                          const SizedBox(height: 16),
                          BudgetProgressBar(
                            spent: txProvider.totalExpense,
                            budget: budgetProvider.overallBudgetAmount,
                            label: '使用済み: ${Formatters.formatCurrency(txProvider.totalExpense)}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '残り: ${Formatters.formatCurrency(budgetProvider.overallBudgetAmount - txProvider.totalExpense)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // カテゴリ別予算
                Text(
                  'カテゴリ別予算（任意）',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '各カテゴリごとに予算を設定できます',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),

                ...categoryProvider.expenseCategories.map((category) {
                  final categoryBudget = budgetProvider.getCategoryBudget(category.id);
                  final categorySpent = txProvider.expenseByCategory[category.id] ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.colorValue.withAlpha(51),
                        child: Icon(
                          category.iconData,
                          color: category.colorValue,
                          size: 20,
                        ),
                      ),
                      title: Text(category.name),
                      subtitle: categoryBudget > 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                BudgetProgressBar(
                                  spent: categorySpent,
                                  budget: categoryBudget,
                                  showPercentage: false,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${Formatters.formatCurrency(categorySpent)} / ${Formatters.formatCurrency(categoryBudget)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            )
                          : const Text('予算未設定'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showBudgetDialog(
                          context,
                          category.name,
                          categoryBudget,
                          (amount) => budgetProvider.setCategoryBudget(category.id, amount),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showBudgetDialog(
    BuildContext context,
    String title,
    double currentAmount,
    Function(double) onSave,
  ) async {
    final controller = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toStringAsFixed(0) : '',
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$titleを設定'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '金額',
            prefixText: '¥ ',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0;
              Navigator.pop(context, amount);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null) {
      if (!mounted) return;
      await onSave(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予算を保存しました')),
      );
    }
  }
}
