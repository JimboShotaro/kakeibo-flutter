import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/month_selector.dart';
import '../widgets/transaction_list_item.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatelessWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('取引履歴'),
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, categoryProvider, child) {
          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactionsByDate = txProvider.transactionsByDate;
          final sortedDates = transactionsByDate.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // 月選択
              MonthSelector(
                year: txProvider.selectedYear,
                month: txProvider.selectedMonth,
                onPrevious: txProvider.previousMonth,
                onNext: txProvider.nextMonth,
              ),
              
              // サマリー
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      context,
                      '支出',
                      txProvider.totalExpense,
                      AppTheme.expenseColor,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    _buildSummaryItem(
                      context,
                      '収入',
                      txProvider.totalIncome,
                      AppTheme.incomeColor,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade300,
                    ),
                    _buildSummaryItem(
                      context,
                      '収支',
                      txProvider.balance,
                      txProvider.balance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                    ),
                  ],
                ),
              ),
              const Divider(),

              // 取引リスト
              Expanded(
                child: transactionsByDate.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('取引がありません'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedDates.length,
                        itemBuilder: (context, index) {
                          final date = sortedDates[index];
                          final transactions = transactionsByDate[date]!;
                          final parsedDate = Formatters.parseDate(date);

                          // この日の支出合計
                          double dayTotal = 0;
                          for (final tx in transactions) {
                            final cat = categoryProvider.getCategoryById(tx.categoryId);
                            if (cat?.isExpense == true) {
                              dayTotal += tx.amount;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.grey.shade100,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '${parsedDate.day}',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${Formatters.getWeekday(parsedDate)})',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: AppTheme.textSecondary,
                                              ),
                                        ),
                                      ],
                                    ),
                                    if (dayTotal > 0)
                                      Text(
                                        '-${Formatters.formatCurrency(dayTotal)}',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: AppTheme.expenseColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              ...transactions.map((tx) => TransactionListItem(
                                    transaction: tx,
                                    category: categoryProvider.getCategoryById(tx.categoryId),
                                    onTap: () => _openEditTransaction(context, tx),
                                    onDelete: () {
                                      context.read<TransactionProvider>().deleteTransaction(tx.id);
                                    },
                                  )),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransaction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          Formatters.formatCurrency(amount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TransactionFormScreen(),
      ),
    );
  }

  void _openEditTransaction(BuildContext context, dynamic transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );
  }
}
