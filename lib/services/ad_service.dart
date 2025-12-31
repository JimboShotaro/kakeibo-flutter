import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告管理サービス
/// 注意: AdMobはAndroid/iOSのみ対応。Web/デスクトップでは広告は表示されません。
class AdService {
  static final AdService instance = AdService._init();
  
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  bool _isInitialized = false;

  AdService._init();

  /// 広告がサポートされているプラットフォームか
  bool get isSupported {
    return !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || 
                       defaultTargetPlatform == TargetPlatform.iOS);
  }

  /// 広告SDKを初期化
  Future<void> initialize() async {
    if (!isSupported) {
      debugPrint('AdMobは現在のプラットフォームではサポートされていません');
      return;
    }
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob初期化完了');
    } catch (e) {
      debugPrint('AdMob初期化エラー: $e');
      _isInitialized = false;
    }
  }

  /// テスト用バナー広告ID
  /// ⚠️ 本番リリース前に実際のAdMob広告ユニットIDに変更してください
  String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android テスト広告ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS テスト広告ID
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      return '';
    }
  }

  /// バナー広告を読み込み
  void loadBannerAd({
    required Function(BannerAd) onAdLoaded,
    required Function() onAdFailedToLoad,
  }) {
    if (!isSupported || !_isInitialized) {
      onAdFailedToLoad();
      return;
    }

    try {
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            onAdLoaded(ad as BannerAd);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _isBannerAdLoaded = false;
            onAdFailedToLoad();
            debugPrint('バナー広告の読み込みに失敗: ${error.message}');
          },
          onAdOpened: (ad) => debugPrint('バナー広告が開かれました'),
          onAdClosed: (ad) => debugPrint('バナー広告が閉じられました'),
        ),
      );

      _bannerAd!.load();
    } catch (e) {
      debugPrint('バナー広告読み込みエラー: $e');
      onAdFailedToLoad();
    }
  }

  /// バナー広告が読み込まれているか
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  /// バナー広告を取得
  BannerAd? get bannerAd => _bannerAd;

  /// 広告ウィジェットを取得
  /// Web/デスクトップではnullを返す
  AdWidget? getAdWidget() {
    if (!isSupported || _bannerAd == null || !_isBannerAdLoaded) {
      return null;
    }
    return AdWidget(ad: _bannerAd!);
  }

  /// 広告を破棄
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}
