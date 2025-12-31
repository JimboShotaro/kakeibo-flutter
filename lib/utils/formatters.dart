import 'package:intl/intl.dart';

/// フォーマッター
class Formatters {
  /// 金額をフォーマット
  static String formatCurrency(double amount, {bool showSign = false}) {
    final formatter = NumberFormat('#,###', 'ja_JP');
    final formatted = formatter.format(amount.abs().round());
    
    if (showSign && amount > 0) {
      return '+¥$formatted';
    } else if (showSign && amount < 0) {
      return '-¥$formatted';
    }
    return '¥$formatted';
  }

  /// 日付をフォーマット
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  /// 日付を短くフォーマット
  static String formatDateShort(DateTime date) {
    return DateFormat('MM/dd').format(date);
  }

  /// 年月をフォーマット
  static String formatYearMonth(int year, int month) {
    return DateFormat('yyyy年M月').format(DateTime(year, month));
  }

  /// 曜日を取得
  static String getWeekday(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return weekdays[date.weekday - 1];
  }

  /// 日付文字列をパース
  static DateTime parseDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// パーセンテージをフォーマット
  static String formatPercentage(double value) {
    return '${(value * 100).toStringAsFixed(1)}%';
  }
}
