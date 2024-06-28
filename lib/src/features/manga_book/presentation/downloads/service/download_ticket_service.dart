import 'dart:async';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../global_providers/global_providers.dart';
import '../../../../../utils/event_util.dart';
import '../../../../../utils/log.dart';
import '../../../../custom/ads/controller/reward_ads_controller.dart';
import '../../../../custom/ads/model/reward_ads_config.dart';
import '../../../../custom/inapp/purchase_providers.dart';

part 'download_ticket_service.g.dart';

const kDownloadTicketPrefix = "ticket:down:";
const kRewardAdCountPrefix = "reward:count:";
const kDownloadUnlimited = -1;

typedef CompleteCallback = void Function(bool reward, bool skip);

@riverpod
class DownloadTicketService extends _$DownloadTicketService {
  Completer<MyRewardAd>? _preloadAd;
  int _lastLoadMs = 0;

  @override
  int build() {
    log("[AD]DownloadTicketService init");
    _clearOldKeys();
    ref.keepAlive();
    return 0;
  }

  int getTicket() {
    if (!_enable()) {
      return kDownloadUnlimited;
    }
    final key = _buildKey();
    return _getTicket(key);
  }

  void increaseTicket(int delta) {
    log("[AD]increaseTicket..");
    if (!_enable()) {
      log("[AD]increaseTicket skip");
      return;
    }
    final key = _buildKey();
    final prev = _getTicket(key);
    log("[AD]increaseTicket key:$key prev:$prev delta:$delta");
    if (prev != kDownloadUnlimited) {
      _setTicket(key, prev + delta);
    }
  }

  bool decreaseTicket(int delta) {
    if (!_enable()) {
      log("[AD]decreaseTicket skip");
      return true;
    }
    final key = _buildKey();
    final prev = _getTicket(key);
    log("[AD]decreaseTicket key:$key prev:$prev delta:$delta");
    if (prev == kDownloadUnlimited) {
      return true;
    }
    if (prev - delta < 0) {
      return false;
    }
    _setTicket(key, prev - delta);
    return true;
  }

  void preloadAd() async {
    log("[AD]preloadAd... ad:$_preloadAd, _lastLoadMs:$_lastLoadMs");
    if (_preloadAdValid()) {
      log("[AD]preloadAd skip");
      return;
    }
    if (!_enable()) {
      log("[AD]preloadAd skip");
      return;
    }
    _preloadAd = _loadAd();
    _lastLoadMs = DateTime.now().millisecondsSinceEpoch;
  }

  bool _preloadAdValid() {
    final valid = _preloadAd != null &&
        DateTime.now().millisecondsSinceEpoch - _lastLoadMs < 3600 * 1000;
    log("[AD]preloadAdValid:$valid");
    return valid;
  }

  Completer<MyRewardAd> _loadAd() {
    if (!_enable()) {
      log("[AD]_loadAd... ad is not enable");
      logEvent3("REWARD:FATAL:ERROR", {"error": "loadAd... ad is not enable"});
      throw "Something is wrong while fetching the ad";
    }
    final config = ref.read(rewardAdsConfigProvider);
    final completer = Completer<MyRewardAd>();
    logEvent3("REWARD:LOAD:START");
    RewardedAd.load(
      adUnitId: config.adId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          logEvent3("REWARD:LOAD:SUCC");
          final myAd = MyRewardAd(ad, null);
          completer.complete(myAd);
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (LoadAdError error) {
          logEvent3("REWARD:LOAD:ERROR", {"error": error.message});
          final myAd = MyRewardAd(null, error);
          completer.complete(myAd);
        },
      ),
    );
    return completer;
  }

  Future<void> showAd(CompleteCallback onAdDismiss, String rewardText) async {
    if (!_enable()) {
      log("[AD]showAd... ad is not enable");
      logEvent3("REWARD:FATAL:ERROR", {"error": "showAd... ad is not enable"});
      throw "Something is wrong while fetching the ad";
    }
    final config = ref.read(rewardAdsConfigProvider);

    final rewardAd = _preloadAdValid() ? _preloadAd : _loadAd();
    _preloadAd = null;

    final myAd = await rewardAd!.future;
    if (myAd.adError != null) {
      if (config.skipWhenError == true) {
        logEvent3("REWARD:SKIP:WHEN:ERROR");
        onAdDismiss(false, true);
        return;
      }
      throw myAd.adError!.message;
    }
    if (myAd.rewardedAd == null) {
      log("[AD]rewardedAd is null");
      logEvent3("REWARD:FATAL:ERROR", {"error": "rewardedAd is null"});
      throw "Something is wrong while fetching the ad";
    }
    var reward = false;
    myAd.rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      // Called when the ad showed the full screen content.
      onAdShowedFullScreenContent: (ad) {},
      // Called when an impression occurs on the ad.
      onAdImpression: (ad) {},
      // Called when the ad failed to show full screen content.
      onAdFailedToShowFullScreenContent: (ad, err) {
        // Dispose the ad here to free resources.
        logEvent3("REWARD:FATAL:ERROR",
            {"error": "onAdFailedToShowFullScreenContent"});
        ad.dispose();
        onAdDismiss(false, false);
      },
      // Called when the ad dismissed full screen content.
      onAdDismissedFullScreenContent: (ad) {
        // Dispose the ad here to free resources.
        ad.dispose();
        onAdDismiss(reward, false);
      },
      // Called when a click is recorded for an ad.
      onAdClicked: (ad) {},
    );
    myAd.rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
        // Reward the user for watching an ad.
        reward = true;
        log("[AD]onUserEarnedReward rewardItem:$rewardItem");
        logEvent3("REWARD:EARN:REWARD");
        Fluttertoast.showToast(msg: rewardText, timeInSecForIosWeb: 3);
        increaseTicket(config.ticketPerAd!);
        _tryMarkUnlimited(config);
      },
    );
  }

  void _tryMarkUnlimited(RewardAdsConfig config) {
    final key = _buildCountKey();
    final prev = ref.read(sharedPreferencesProvider).getInt(key) ?? 0;
    final next = prev + 1;
    ref.read(sharedPreferencesProvider).setInt(key, next);
    log("[AD]_tryMarkUnlimited next:$next");
    if (config.maxAds != null && next >= config.maxAds!) {
      log("[AD]_tryMarkUnlimited unlimited");
      logEvent3("REWARD:EARN:UNLIMITED");
      _setTicket(_buildKey(), kDownloadUnlimited);
    }
  }

  bool _enable() {
    final purchaseGate = ref.read(purchaseGateProvider);
    final testflightFlag = ref.read(testflightFlagProvider);
    if (purchaseGate || testflightFlag) {
      return false;
    }
    final config = ref.read(rewardAdsConfigProvider);
    final oldUser = _isOldUser(config);
    return config.enable == true && config.adId != null && oldUser;
  }

  bool _isOldUser(RewardAdsConfig config) {
    var oldUser = true;
    final firstInitTimeStr =
        ref.read(sharedPreferencesProvider).getString("mc.app.init");
    if (config.minDays != null &&
        config.minDays != 0 &&
        firstInitTimeStr != null) {
      final firstInitTime = double.tryParse(firstInitTimeStr);
      if (firstInitTime != null) {
        final interval =
            DateTime.now().millisecondsSinceEpoch - firstInitTime * 1000;
        final days = interval / (86400 * 1000);
        if (days < config.minDays!) {
          oldUser = false;
        }
        log("[AD]oldUser days:$days, oldUser: $oldUser");
      }
    }
    return oldUser;
  }

  int _getTicket(String key) {
    final value = ref.read(sharedPreferencesProvider).getInt(key);
    if (value != null) {
      return value;
    }
    final config = ref.read(rewardAdsConfigProvider);
    return config.freeTicket ?? kDownloadUnlimited;
  }

  void _setTicket(String key, final value) {
    log("[AD]_setTicket key:$key value:$value ");
    ref.read(sharedPreferencesProvider).setInt(key, value);
  }

  String _buildKey() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return "$kDownloadTicketPrefix$formattedDate";
  }

  String _buildCountKey() {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return "$kRewardAdCountPrefix$formattedDate";
  }

  void _clearOldKeys() {
    DateTime now = DateTime.now();
    for (int i = 1; i <= 7; i++) {
      DateTime date = now.subtract(Duration(days: i));
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      String key1 = "$kDownloadTicketPrefix$formattedDate";
      String key2 = "$kRewardAdCountPrefix$formattedDate";
      ref.read(sharedPreferencesProvider).remove(key1);
      ref.read(sharedPreferencesProvider).remove(key2);
    }
  }
}

class MyRewardAd {
  RewardedAd? rewardedAd;
  LoadAdError? adError;

  MyRewardAd(this.rewardedAd, this.adError);
}
