import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static const String _kCurrentStreak    = 'streak_current';
  static const String _kBestStreak       = 'streak_best';
  static const String _kLastCompletedDate= 'streak_last_date';
  static const String _kTotalCompleted   = 'streak_total_completed';
  static const String _kTodayCompleted   = 'streak_today_completed';

  static Future<void> onTaskCompleted() async {
    final prefs   = await SharedPreferences.getInstance();
    final today   = _dateKey(DateTime.now());
    final lastDate= prefs.getString(_kLastCompletedDate);
    final todayCount = prefs.getInt(_kTodayCompleted) ?? 0;
    final total   = prefs.getInt(_kTotalCompleted) ?? 0;

    await prefs.setInt(_kTotalCompleted, total + 1);

    if (lastDate == today) {
      // already counted streak for today — just increment today count
      await prefs.setInt(_kTodayCompleted, todayCount + 1);
      return;
    }

    // new day — update streak
    int current = prefs.getInt(_kCurrentStreak) ?? 0;
    int best    = prefs.getInt(_kBestStreak) ?? 0;

    if (lastDate == null) {
      current = 1;
    } else {
      final last = _parseDate(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      current    = diff == 1 ? current + 1 : 1;
    }

    if (current > best) best = current;

    await prefs.setInt(_kCurrentStreak, current);
    await prefs.setInt(_kBestStreak, best);
    await prefs.setInt(_kTodayCompleted, todayCount + 1);
    await prefs.setString(_kLastCompletedDate, today);
  }

  static Future<void> onTaskUncompleted() async {
    final prefs      = await SharedPreferences.getInstance();
    final today      = _dateKey(DateTime.now());
    final lastDate   = prefs.getString(_kLastCompletedDate);
    final todayCount = prefs.getInt(_kTodayCompleted) ?? 0;
    final total      = prefs.getInt(_kTotalCompleted) ?? 0;

    if (total > 0) await prefs.setInt(_kTotalCompleted, total - 1);

    // only roll back streak if this uncomplete brings today's count to 0
    if (lastDate == today && todayCount > 0) {
      final newTodayCount = todayCount - 1;
      await prefs.setInt(_kTodayCompleted, newTodayCount);

      if (newTodayCount == 0) {
        // no tasks completed today anymore — roll back streak
        int current = prefs.getInt(_kCurrentStreak) ?? 0;
        if (current > 0) {
          current -= 1;
          await prefs.setInt(_kCurrentStreak, current);
        }
        // remove today from last completed date
        // find previous date by looking at current streak
        await prefs.remove(_kLastCompletedDate);
      }
    }
  }

  static Future<StreakData> getStreakData() async {
    final prefs   = await SharedPreferences.getInstance();
    final lastDate= prefs.getString(_kLastCompletedDate);

    int current = prefs.getInt(_kCurrentStreak) ?? 0;

    // check if streak is still alive — reset if missed a day
    if (lastDate != null) {
      final last = _parseDate(lastDate);
      final diff = DateTime.now().difference(last).inDays;
      if (diff > 1) {
        current = 0;
        await prefs.setInt(_kCurrentStreak, 0);
        await prefs.setInt(_kTodayCompleted, 0);
      }
    }

    return StreakData(
      currentStreak : current,
      bestStreak    : prefs.getInt(_kBestStreak) ?? 0,
      totalCompleted: prefs.getInt(_kTotalCompleted) ?? 0,
      lastActiveDate: lastDate != null ? _parseDate(lastDate) : null,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static DateTime _parseDate(String key) {
    final parts = key.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }
}

class StreakData {
  final int currentStreak;
  final int bestStreak;
  final int totalCompleted;
  final DateTime? lastActiveDate;

  const StreakData({
    required this.currentStreak,
    required this.bestStreak,
    required this.totalCompleted,
    this.lastActiveDate,
  });

  String get streakEmoji {
    if (currentStreak == 0)  return '💤';
    if (currentStreak < 7)   return '🔥';
    if (currentStreak < 14)  return '⚡';
    if (currentStreak < 30)  return '💪';
    return '🏆';
  }

  String get streakMessage {
    if (currentStreak == 0)  return 'Start your streak today!';
    if (currentStreak == 1)  return 'Great start! Keep going!';
    if (currentStreak < 7)   return 'Building momentum!';
    if (currentStreak < 14)  return 'One week strong!';
    if (currentStreak < 30)  return 'On fire! Don\'t stop!';
    return 'Legendary streak!';
  }
}