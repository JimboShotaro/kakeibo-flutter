import 'package:flutter/material.dart';
import '../services/ad_service.dart';

/// バナー広告ウィジェット
/// Web/デスクトップではプレースホルダーを表示（広告なし）
/// Android/iOSでのみ実際の広告を表示
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    // サポートされているプラットフォームでのみ広告を読み込む
    if (AdService.instance.isSupported) {
      _loadAd();
    }
  }

  void _loadAd() {
    AdService.instance.loadBannerAd(
      onAdLoaded: (ad) {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      },
      onAdFailedToLoad: () {
        if (mounted) {
          setState(() {
            _isLoaded = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // サポートされていないプラットフォームでは何も表示しない
    if (!AdService.instance.isSupported) {
      return const SizedBox.shrink();
    }

    // 広告読み込み中または失敗時
    if (!_isLoaded) {
      return const SizedBox(height: 50);
    }

    // 広告ウィジェットを取得
    final adWidget = AdService.instance.getAdWidget();
    if (adWidget == null) {
      return const SizedBox(height: 50);
    }

    final bannerAd = AdService.instance.bannerAd;
    return Container(
      alignment: Alignment.center,
      width: bannerAd?.size.width.toDouble() ?? 320,
      height: bannerAd?.size.height.toDouble() ?? 50,
      child: adWidget,
    );
  }
}
