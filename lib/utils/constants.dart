/// アプリ定数
class Constants {
  // アプリ情報
  static const String appName = '家計簿';
  static const String appVersion = '1.0.0';

  // データベース
  static const String dbName = 'kakeibo.db';
  static const int dbVersion = 1;

  // 予算アラート閾値
  static const double warningThreshold = 0.8;  // 80%
  static const double criticalThreshold = 1.0; // 100%

  // 予測アラート閾値
  static const double forecastWarningThreshold = 1.0;  // 100%
  static const double forecastCriticalThreshold = 1.2; // 120%

  // UIサイズ
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
}
