import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_settings.dart';

class SettingsProvider with ChangeNotifier {
  AppSettings _settings = const AppSettings();
  bool _isLoading = false;

  AppSettings get settings => _settings;
  bool get isLoading => _isLoading;

  /// 設定を読み込み
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString('app_settings');
      
      if (settingsJson != null) {
        final map = json.decode(settingsJson) as Map<String, dynamic>;
        _settings = AppSettings.fromMap(map);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 設定を保存
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_settings', json.encode(_settings.toMap()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  /// 背景色を設定
  Future<void> setBackgroundColor(String colorHex) async {
    _settings = _settings.copyWith(
      backgroundType: BackgroundType.color,
      backgroundValue: colorHex,
    );
    await _saveSettings();
    notifyListeners();
  }

  /// グラデーション背景を設定
  Future<void> setBackgroundGradient(String startColor, String endColor) async {
    _settings = _settings.copyWith(
      backgroundType: BackgroundType.gradient,
      backgroundValue: startColor,
      gradientEndColor: endColor,
    );
    await _saveSettings();
    notifyListeners();
  }

  /// 背景画像を設定
  Future<void> setBackgroundImage(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'background_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await imageFile.copy('${appDir.path}/$fileName');

      _settings = _settings.copyWith(
        backgroundType: BackgroundType.image,
        backgroundValue: savedImage.path,
      );
      await _saveSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving background image: $e');
    }
  }

  /// テーマモードを設定
  Future<void> setThemeMode(String mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  /// 予算残額表示設定
  Future<void> setShowBudgetRemaining(bool show) async {
    _settings = _settings.copyWith(showBudgetRemaining: show);
    await _saveSettings();
    notifyListeners();
  }

  /// カレンダーデフォルト表示を設定
  Future<void> setCalendarDefaultView(CalendarViewMode view) async {
    _settings = _settings.copyWith(calendarDefaultView: view);
    await _saveSettings();
    notifyListeners();
  }

  /// ThemeModeを取得
  ThemeMode getThemeMode() {
    switch (_settings.themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// 背景のDecorationを取得
  BoxDecoration? getBackgroundDecoration() {
    switch (_settings.backgroundType) {
      case BackgroundType.color:
        return BoxDecoration(
          color: Color(int.parse(_settings.backgroundValue.replaceFirst('#', '0xFF'))),
        );
      case BackgroundType.gradient:
        final startColor = Color(int.parse(_settings.backgroundValue.replaceFirst('#', '0xFF')));
        final endColor = _settings.gradientEndColor != null
            ? Color(int.parse(_settings.gradientEndColor!.replaceFirst('#', '0xFF')))
            : startColor;
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [startColor, endColor],
          ),
        );
      case BackgroundType.image:
        return BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(_settings.backgroundValue)),
            fit: BoxFit.cover,
          ),
        );
    }
  }
}
