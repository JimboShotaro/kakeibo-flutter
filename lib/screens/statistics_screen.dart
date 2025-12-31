import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../widgets/month_selector.dart';
import '../widgets/category_pie_chart.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../services/analysis_service.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analysisService = AnalysisService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計'),
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, categoryProvider, child) {
          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月選択
                MonthSelector(
                  year: txProvider.selectedYear,
                  month: txProvider.selectedMonth,
                  onPrevious: txProvider.previousMonth,
                  onNext: txProvider.nextMonth,
                ),
                const SizedBox(height: 24),

                // サマリー
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        '支出合計',
                        txProvider.totalExpense,
                        Icons.arrow_downward,
                        AppTheme.expenseColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        '収入合計',
                        txProvider.totalIncome,
                        Icons.arrow_upward,
                        AppTheme.incomeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // カテゴリ別支出
                if (txProvider.expenseByCategory.isNotEmpty) ...[
                  Text(
                    'カテゴリ別支出',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CategoryPieChart(
                        data: txProvider.expenseByCategory,
                        categories: categoryProvider.expenseCategories,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // カテゴリ別ランキング
                  Text(
                    'カテゴリ別ランキング',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Column(
                      children: txProvider.sortedExpenseByCategory.map((entry) {
                        final category = categoryProvider.getCategoryById(entry.key);
                        final total = txProvider.totalExpense;
                        final percentage = total > 0 ? (entry.value / total) : 0.0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: category?.colorValue.withAlpha(51) ?? Colors.grey.shade200,
                            child: Icon(
                              category?.iconData ?? Icons.category,
                              color: category?.colorValue ?? Colors.grey,
                              size: 20,
                            ),
                          ),
                          title: Text(category?.name ?? '不明'),
                          subtitle: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              category?.colorValue ?? Colors.grey,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.formatCurrency(entry.value),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                Formatters.formatPercentage(percentage),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // 日別推移グラフ
                if (txProvider.dailyExpense.isNotEmpty) ...[
                  Text(
                    '日別支出推移',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 200,
                        child: _buildDailyChart(context, txProvider, analysisService),
                      ),
                    ),
                  ),
                ],

                // データがない場合
                if (txProvider.expenseByCategory.isEmpty && txProvider.dailyExpense.isEmpty)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 64),
                        Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('この月のデータがありません'),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              Formatters.formatCurrency(amount),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart(
    BuildContext context,
    TransactionProvider txProvider,
    AnalysisService analysisService,
  ) {
    final dailyExpense = txProvider.dailyExpense;
    final daysInMonth = analysisService.getDaysInMonth(
      txProvider.selectedYear,
      txProvider.selectedMonth,
    );

    // 日別データを準備
    List<FlSpot> spots = [];
    double maxY = 0;
    
    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = '${txProvider.selectedYear}-${txProvider.selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final amount = dailyExpense[dateStr] ?? 0.0;
      spots.add(FlSpot(day.toDouble(), amount));
      if (amount > maxY) maxY = amount;
    }

    if (maxY == 0) maxY = 10000;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0 || value == 1) {
                  return Text(
                    '${value.toInt()}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        maxY: maxY * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.expenseColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.expenseColor.withAlpha(26),
            ),
          ),
        ],
      ),
    );
  }
}
