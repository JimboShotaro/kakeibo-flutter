import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告管理サービス
class AdService {
  static final AdService instance = AdService._init();
  
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  AdService._init();

  /// 広告SDKを初期化
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  /// テスト用バナー広告ID
  /// ⚠️ 本番リリース前に実際のAdMob広告ユニットIDに変更してください
  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Android テスト広告ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // iOS テスト広告ID
      return 'ca-app-pub-3940256099942544/2934735716';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// バナー広告を読み込み
  void loadBannerAd({
    required Function(BannerAd) onAdLoaded,
    required Function() onAdFailedToLoad,
  }) {
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
          print('バナー広告の読み込みに失敗: ${error.message}');
        },
        onAdOpened: (ad) => print('バナー広告が開かれました'),
        onAdClosed: (ad) => print('バナー広告が閉じられました'),
      ),
    );

    _bannerAd!.load();
  }

  /// バナー広告が読み込まれているか
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  /// バナー広告を取得
  BannerAd? get bannerAd => _bannerAd;

  /// 広告を破棄
  void dispose() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}
