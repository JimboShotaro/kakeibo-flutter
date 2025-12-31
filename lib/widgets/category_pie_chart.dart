import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category.dart';
import '../utils/formatters.dart';

/// カテゴリ別円グラフWidget
class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;
  final List<AppCategory> categories;
  final double centerRadius;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.categories,
    this.centerRadius = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('データがありません'),
      );
    }

    final total = data.values.fold(0.0, (sum, val) => sum + val);
    
    final sections = data.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => AppCategory(
          id: entry.key,
          name: '不明',
          icon: 'more_horiz',
          color: '#607D8B',
          isExpense: true,
        ),
      );
      final percentage = (entry.value / total) * 100;

      return PieChartSectionData(
        color: category.colorValue,
        value: entry.value,
        title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: centerRadius,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context, total),
      ],
    );
  }

  Widget _buildLegend(BuildContext context, double total) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: sortedEntries.take(6).map((entry) {
        final category = categories.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => AppCategory(
            id: entry.key,
            name: '不明',
            icon: 'more_horiz',
            color: '#607D8B',
            isExpense: true,
          ),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: category.colorValue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${category.name}: ${Formatters.formatCurrency(entry.value)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
}
