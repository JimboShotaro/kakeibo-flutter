import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/summary_card.dart';
import '../widgets/budget_progress_bar.dart';
import '../widgets/month_selector.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/transaction_list_item.dart';
import '../utils/theme.dart';
import '../utils/formatters.dart';
import '../services/analysis_service.dart';
import 'transaction_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnalysisService _analysisService = AnalysisService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final txProvider = context.read<TransactionProvider>();
    final budgetProvider = context.read<BudgetProvider>();
    final categoryProvider = context.read<CategoryProvider>();

    await categoryProvider.loadCategories();
    await txProvider.loadTransactions();
    budgetProvider.setSelectedMonth(txProvider.selectedYear, txProvider.selectedMonth);
    await budgetProvider.loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('家計簿'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 設定画面への遷移（将来実装）
            },
          ),
        ],
      ),
      body: Consumer3<TransactionProvider, BudgetProvider, CategoryProvider>(
        builder: (context, txProvider, budgetProvider, categoryProvider, child) {
          if (txProvider.isLoading || categoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 月選択
                  MonthSelector(
                    year: txProvider.selectedYear,
                    month: txProvider.selectedMonth,
                    onPrevious: () {
                      txProvider.previousMonth();
                      budgetProvider.setSelectedMonth(
                        txProvider.selectedYear,
                        txProvider.selectedMonth,
                      );
                    },
                    onNext: () {
                      txProvider.nextMonth();
                      budgetProvider.setSelectedMonth(
                        txProvider.selectedYear,
                        txProvider.selectedMonth,
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // サマリーカード
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: '支出',
                          amount: txProvider.totalExpense,
                          icon: Icons.arrow_downward,
                          color: AppTheme.expenseColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: '収入',
                          amount: txProvider.totalIncome,
                          icon: Icons.arrow_upward,
                          color: AppTheme.incomeColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 予算進捗
                  if (budgetProvider.overallBudgetAmount > 0) ...[
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
                                  '予算',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  '残り: ${Formatters.formatCurrency(budgetProvider.overallBudgetAmount - txProvider.totalExpense)}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            BudgetProgressBar(
                              spent: txProvider.totalExpense,
                              budget: budgetProvider.overallBudgetAmount,
                              label: '${Formatters.formatCurrency(txProvider.totalExpense)} / ${Formatters.formatCurrency(budgetProvider.overallBudgetAmount)}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 月末予測
                  _buildForecastCard(context, txProvider, budgetProvider),
                  const SizedBox(height: 16),

                  // カテゴリ別円グラフ
                  if (txProvider.expenseByCategory.isNotEmpty) ...[
                    Text(
                      'カテゴリ別支出',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CategoryPieChart(
                          data: txProvider.expenseByCategory,
                          categories: categoryProvider.expenseCategories,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 直近の取引
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '直近の取引',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // 履歴画面への遷移（BottomNavigationで制御）
                        },
                        child: const Text('すべて見る'),
                      ),
                    ],
                  ),
                  Card(
                    child: txProvider.transactions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('取引がありません'),
                            ),
                          )
                        : Column(
                            children: txProvider.transactions
                                .take(5)
                                .map((tx) => TransactionListItem(
                                      transaction: tx,
                                      category: categoryProvider.getCategoryById(tx.categoryId),
                                      onTap: () => _openEditTransaction(tx),
                                      onDelete: () => txProvider.deleteTransaction(tx.id),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
    );
  }

  Widget _buildForecastCard(
    BuildContext context,
    TransactionProvider txProvider,
    BudgetProvider budgetProvider,
  ) {
    final forecast = txProvider.forecastExpense;
    final budget = budgetProvider.overallBudgetAmount;
    final alertLevel = _analysisService.getForecastAlertLevel(
      forecast: forecast,
      budget: budget,
    );

    Color alertColor;
    String alertText;
    IconData alertIcon;

    switch (alertLevel) {
      case 'critical':
        alertColor = AppTheme.errorColor;
        alertText = '予算を大幅に超過する見込みです';
        alertIcon = Icons.warning;
        break;
      case 'warning':
        alertColor = AppTheme.warningColor;
        alertText = '予算を超える可能性があります';
        alertIcon = Icons.info;
        break;
      default:
        alertColor = AppTheme.successColor;
        alertText = '予算内で推移しています';
        alertIcon = Icons.check_circle;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '月末予測',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              Formatters.formatCurrency(forecast),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (budget > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: alertColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(alertIcon, size: 16, color: alertColor),
                    const SizedBox(width: 4),
                    Text(
                      alertText,
                      style: TextStyle(color: alertColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openAddTransaction() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );
  }

  void _openEditTransaction(dynamic transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );
  }
}
