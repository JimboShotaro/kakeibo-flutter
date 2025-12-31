import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

/// 予算残額を大きく表示するカード
class BudgetRemainingCard extends StatelessWidget {
  final double budgetAmount;
  final double spentAmount;
  final int daysLeft;

  const BudgetRemainingCard({
    super.key,
    required this.budgetAmount,
    required this.spentAmount,
    required this.daysLeft,
  });

  double get remaining => budgetAmount - spentAmount;
  double get dailyRemaining => daysLeft > 0 ? remaining / daysLeft : 0;
  double get percentageRemaining => budgetAmount > 0 ? remaining / budgetAmount : 0;

  String get status {
    if (remaining < 0) return 'over';
    if (percentageRemaining >= 0.3) return 'safe';
    if (percentageRemaining >= 0.1) return 'warning';
    return 'danger';
  }

  Color get statusColor {
    switch (status) {
      case 'safe':
        return AppTheme.successColor;
      case 'warning':
        return AppTheme.warningColor;
      case 'danger':
      case 'over':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String get statusMessage {
    switch (status) {
      case 'safe':
        return '順調です！';
      case 'warning':
        return '少し注意が必要です';
      case 'danger':
        return '予算残りわずか';
      case 'over':
        return '予算オーバー';
      default:
        return '';
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'safe':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'danger':
      case 'over':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (budgetAmount <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withAlpha(40),
              statusColor.withAlpha(10),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  statusMessage,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '今月の残額',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              Formatters.formatCurrency(remaining),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: remaining >= 0 ? statusColor : AppTheme.errorColor,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoColumn(
                  context,
                  '1日あたり',
                  Formatters.formatCurrency(dailyRemaining.abs()),
                  dailyRemaining >= 0 ? AppTheme.textPrimary : AppTheme.errorColor,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildInfoColumn(
                  context,
                  '残り日数',
                  '$daysLeft日',
                  AppTheme.textPrimary,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _buildInfoColumn(
                  context,
                  '消化率',
                  '${((1 - percentageRemaining) * 100).clamp(0, 999).toStringAsFixed(0)}%',
                  status == 'over' ? AppTheme.errorColor : AppTheme.textPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
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
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
        ),
      ],
    );
  }
}
