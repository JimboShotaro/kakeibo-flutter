/// 背景タイプ
enum BackgroundType {
  color,
  gradient,
  image,
}

/// カレンダー表示モード
enum CalendarViewMode {
  month,
  week,
}

/// アプリ設定モデル
class AppSettings {
  final BackgroundType backgroundType;
  final String backgroundValue; // 色コード or グラデーション or 画像パス
  final String? gradientEndColor; // グラデーション終了色
  final String themeMode; // light, dark, system
  final bool showBudgetRemaining;
  final CalendarViewMode calendarDefaultView;

  const AppSettings({
    this.backgroundType = BackgroundType.color,
    this.backgroundValue = '#F5F5F5',
    this.gradientEndColor,
    this.themeMode = 'system',
    this.showBudgetRemaining = true,
    this.calendarDefaultView = CalendarViewMode.month,
  });

  AppSettings copyWith({
    BackgroundType? backgroundType,
    String? backgroundValue,
    String? gradientEndColor,
    String? themeMode,
    bool? showBudgetRemaining,
    CalendarViewMode? calendarDefaultView,
  }) {
    return AppSettings(
      backgroundType: backgroundType ?? this.backgroundType,
      backgroundValue: backgroundValue ?? this.backgroundValue,
      gradientEndColor: gradientEndColor ?? this.gradientEndColor,
      themeMode: themeMode ?? this.themeMode,
      showBudgetRemaining: showBudgetRemaining ?? this.showBudgetRemaining,
      calendarDefaultView: calendarDefaultView ?? this.calendarDefaultView,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'backgroundType': backgroundType.index,
      'backgroundValue': backgroundValue,
      'gradientEndColor': gradientEndColor,
      'themeMode': themeMode,
      'showBudgetRemaining': showBudgetRemaining,
      'calendarDefaultView': calendarDefaultView.index,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      backgroundType: BackgroundType.values[map['backgroundType'] ?? 0],
      backgroundValue: map['backgroundValue'] ?? '#F5F5F5',
      gradientEndColor: map['gradientEndColor'],
      themeMode: map['themeMode'] ?? 'system',
      showBudgetRemaining: map['showBudgetRemaining'] ?? true,
      calendarDefaultView: CalendarViewMode.values[map['calendarDefaultView'] ?? 0],
    );
  }
}
