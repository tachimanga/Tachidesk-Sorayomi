import 'package:shared_preferences/shared_preferences.dart';
import 'log.dart';

class UsageUtil {
  static int calculateUsageDays(SharedPreferences sharedPreferences) {
    var days = 0;
    try {
      days = _calculateUsageDays(sharedPreferences);
    } catch (e) {
      log("calculateUsageDays err:$e");
    }
    return days;
  }

  static int _calculateUsageDays(SharedPreferences sharedPreferences) {
    final firstInitTimeStr = sharedPreferences.getString("mc.app.init");
    if (firstInitTimeStr != null) {
      final firstInitTime = double.tryParse(firstInitTimeStr);
      if (firstInitTime != null) {
        final interval =
            DateTime.now().millisecondsSinceEpoch - firstInitTime * 1000;
        final days = interval / (86400 * 1000);
        return days.toInt();
      }
    }
    return 0;
  }
}
