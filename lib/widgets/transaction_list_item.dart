import 'package:flutter/material.dart';
import '../models/transaction.dart' as app;
import '../models/category.dart';
import '../utils/formatters.dart';
import '../utils/theme.dart';

/// 取引リストアイテムWidget
class TransactionListItem extends StatelessWidget {
  final app.Transaction transaction;
  final AppCategory? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionListItem({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = category?.isExpense ?? true;
    final amountColor = isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final amountPrefix = isExpense ? '-' : '+';

    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
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
      },
      onDismissed: (direction) => onDelete?.call(),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: category?.colorValue.withAlpha(51) ?? Colors.grey.shade200,
          child: Icon(
            category?.iconData ?? Icons.help_outline,
            color: category?.colorValue ?? Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          category?.name ?? '不明',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: transaction.note.isNotEmpty
            ? Text(
                transaction.note,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Text(
          '$amountPrefix${Formatters.formatCurrency(transaction.amount)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
