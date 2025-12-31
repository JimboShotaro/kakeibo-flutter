import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// 予算進捗バーWidget
class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String? label;
  final bool showPercentage;

  const BudgetProgressBar({
    super.key,
    required this.spent,
    required this.budget,
    this.label,
    this.showPercentage = true,
  });

  double get progress => budget > 0 ? (spent / budget).clamp(0.0, 1.5) : 0.0;
  double get displayProgress => progress.clamp(0.0, 1.0);

  Color get progressColor {
    if (progress >= 1.0) return AppTheme.errorColor;
    if (progress >= 0.8) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (showPercentage)
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: displayProgress,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
