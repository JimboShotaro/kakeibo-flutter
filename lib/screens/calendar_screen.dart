import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/app_settings.dart';
import '../models/transaction.dart' as app;
import '../utils/formatters.dart';
import '../utils/theme.dart';
import '../widgets/transaction_list_item.dart';
import 'transaction_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final settingsProvider = context.read<SettingsProvider>();
    _calendarFormat = settingsProvider.settings.calendarDefaultView == CalendarViewMode.week
        ? CalendarFormat.week
        : CalendarFormat.month;
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
        actions: [
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.view_week
                  : Icons.calendar_month,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
            tooltip: _calendarFormat == CalendarFormat.month ? '週表示' : '月表示',
          ),
        ],
      ),
      body: Consumer2<TransactionProvider, CategoryProvider>(
        builder: (context, txProvider, categoryProvider, child) {
          return Column(
            children: [
              _buildCalendar(txProvider),
              const Divider(height: 1),
              Expanded(
                child: _buildDayTransactions(txProvider, categoryProvider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(TransactionProvider txProvider) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
        // 月が変わったらデータを再読み込み
        txProvider.setSelectedMonth(focusedDay.year, focusedDay.month);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          return _buildDayMarker(date, txProvider);
        },
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) => Formatters.formatYearMonthDate(date),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryColor.withAlpha(100),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: const TextStyle(color: Colors.red),
      ),
      locale: 'ja_JP',
    );
  }

  Widget? _buildDayMarker(DateTime date, TransactionProvider txProvider) {
    final dateStr = Formatters.formatDateForDb(date);
    final dayExpense = txProvider.dailyExpense[dateStr] ?? 0.0;
    final dayIncome = txProvider.dailyIncome[dateStr] ?? 0.0;

    if (dayExpense == 0 && dayIncome == 0) return null;

    return Positioned(
      bottom: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dayExpense > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '▼${_formatShort(dayExpense)}',
                style: const TextStyle(
                  fontSize: 8,
                  color: AppTheme.expenseColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          if (dayIncome > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '▲${_formatShort(dayIncome)}',
                style: const TextStyle(
                  fontSize: 8,
                  color: AppTheme.incomeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatShort(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}万';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}k';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildDayTransactions(
    TransactionProvider txProvider,
    CategoryProvider categoryProvider,
  ) {
    if (_selectedDay == null) {
      return const Center(child: Text('日付を選択してください'));
    }

    final selectedDateStr = Formatters.formatDateForDb(_selectedDay!);
    final dayTransactions = txProvider.transactions
        .where((tx) => Formatters.formatDateForDb(tx.date) == selectedDateStr)
        .toList();

    final dayExpense = txProvider.dailyExpense[selectedDateStr] ?? 0.0;
    final dayIncome = txProvider.dailyIncome[selectedDateStr] ?? 0.0;

    return Column(
      children: [
        // 日付サマリー
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    Formatters.formatDate(_selectedDay!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    '${dayTransactions.length}件の取引',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('支出', style: TextStyle(color: AppTheme.expenseColor)),
                  Text(
                    Formatters.formatCurrency(dayExpense),
                    style: const TextStyle(
                      color: AppTheme.expenseColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text('収入', style: TextStyle(color: AppTheme.incomeColor)),
                  Text(
                    Formatters.formatCurrency(dayIncome),
                    style: const TextStyle(
                      color: AppTheme.incomeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 取引リスト
        Expanded(
          child: dayTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_note, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text('この日の取引はありません'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: dayTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = dayTransactions[index];
                    return TransactionListItem(
                      transaction: tx,
                      category: categoryProvider.getCategoryById(tx.categoryId),
                      onTap: () => _openEditTransaction(tx),
                      onDelete: () => txProvider.deleteTransaction(tx.id),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openEditTransaction(app.Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(transaction: transaction),
      ),
    );
  }
}
