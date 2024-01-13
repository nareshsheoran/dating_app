import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAdsProvider extends ChangeNotifier {
  RewardedInterstitialAd? rewardedInterstitialAd;
  int messageCount = 0;
  int numRewardedLoadAttempts = 0;
  String googleAdId = 'ca-app-pub-3940256099942544/5354046379';
  String messageCountKey = "messageCountKey_";

  void incrementMessageCount(String chatId) {
    messageCount++;
    saveMessageCount(chatId);
    notifyListeners();
    if (messageCount == 15) {
      messageCount = 0;
      showRewardAd();
      saveMessageCount(chatId);
      notifyListeners();
    }
  }

  void loadMessageCount(String chatId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    messageCount = prefs.getInt('$messageCountKey$chatId') ?? 0;
    notifyListeners();
  }

  void saveMessageCount(String chatId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('$messageCountKey$chatId', messageCount);
  }

  void loadRewardAd() {
    RewardedInterstitialAd.load(
      adUnitId: googleAdId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          rewardedInterstitialAd = ad;
          numRewardedLoadAttempts = 0;
          notifyListeners();
        },
        onAdFailedToLoad: (LoadAdError error) {
          rewardedInterstitialAd = null;
          numRewardedLoadAttempts += 1;
          notifyListeners();
          if (numRewardedLoadAttempts < 3) {
            loadRewardAd();
          }
          if (kDebugMode) {
            print('Rewarded ad failed to load: $error');
          }
        },
      ),
    );
  }

  void showRewardAd() {
    loadRewardAd();
    if (rewardedInterstitialAd != null) {
      rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdClicked: (RewardedInterstitialAd ad) {},
        onAdWillDismissFullScreenContent: (RewardedInterstitialAd ad) {},
        onAdShowedFullScreenContent: (RewardedInterstitialAd ad) {},
        onAdImpression: (RewardedInterstitialAd ad) {},
        onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
          ad.dispose();
          loadRewardAd();
        },
        onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
          if (kDebugMode) {
            print('Failed to show RewardedAd ad: $error');
          }
          ad.dispose();
          loadRewardAd();
        },
      );
      rewardedInterstitialAd?.setImmersiveMode(true);
      rewardedInterstitialAd?.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          if (kDebugMode) {
            print('User earned reward: ${reward.amount} ${reward.type}');
          }
        },
      );
    } else {
      if (kDebugMode) {
        print('Reward ad not loaded yet.');
      }
    }
  }
}
