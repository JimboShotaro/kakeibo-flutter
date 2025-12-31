/// 集計・分析サービス
class AnalysisService {
  /// 月末支出予測（線形予測）
  /// 計算式: (現在の合計 / 経過日数) × 月の総日数
  double predictMonthlyTotal({
    required double currentTotal,
    required int daysElapsed,
    required int daysInMonth,
  }) {
    if (daysElapsed == 0) return 0.0;
    final dailyAvg = currentTotal / daysElapsed;
    return dailyAvg * daysInMonth;
  }

  /// 予算消化率を計算 (0.0 ~ 1.0+)
  double calculateBudgetProgress({
    required double spent,
    required double budget,
  }) {
    if (budget <= 0) return 0.0;
    return spent / budget;
  }

  /// アラートレベルを判定
  /// - normal: 予算消化率 < 80%
  /// - warning: 80% <= 予算消化率 < 100%
  /// - critical: 予算消化率 >= 100%
  String getAlertLevel({
    required double spent,
    required double budget,
  }) {
    final progress = calculateBudgetProgress(spent: spent, budget: budget);
    if (progress >= 1.0) return 'critical';
    if (progress >= 0.8) return 'warning';
    return 'normal';
  }

  /// 予測に基づくアラートレベル
  String getForecastAlertLevel({
    required double forecast,
    required double budget,
  }) {
    if (budget <= 0) return 'normal';
    final ratio = forecast / budget;
    if (ratio >= 1.2) return 'critical';
    if (ratio >= 1.0) return 'warning';
    return 'normal';
  }

  /// 月の日数を取得
  int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 月初からの経過日数を取得
  int getDaysElapsed(int year, int month, {DateTime? today}) {
    final now = today ?? DateTime.now();
    
    // 指定月が現在月より過去なら、その月の全日数を返す
    if (year < now.year || (year == now.year && month < now.month)) {
      return getDaysInMonth(year, month);
    }
    
    // 指定月が未来なら0を返す
    if (year > now.year || (year == now.year && month > now.month)) {
      return 0;
    }
    
    // 現在月なら今日までの日数を返す
    return now.day;
  }
}
