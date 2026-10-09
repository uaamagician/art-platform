import 'dart:math';

import '../models/user_profile.dart';

/// Experience is never shown as a number; only the level and a progress bar are.
class LevelInfo {
  final int level;
  final double progress;

  const LevelInfo(this.level, this.progress);
}

int _xp(UserStats s) =>
    30 * s.posts + 5 * s.comments + 2 * s.liked + 4 * s.followers + s.following;

int _xpForLevel(int level) => 20 * (level - 1) * (level - 1);

LevelInfo computeLevel(UserStats stats) {
  final xp = _xp(stats);
  final level = 1 + sqrt(xp / 20).floor();
  final base = _xpForLevel(level);
  final next = _xpForLevel(level + 1);
  return LevelInfo(level, ((xp - base) / (next - base)).clamp(0.0, 1.0));
}

class Achievement {
  final String title;
  final String description;
  final bool unlocked;

  const Achievement(this.title, this.description, this.unlocked);
}

List<Achievement> achievementsFor(UserStats s) => [
      Achievement('初次發布', '發布第一件作品', s.posts >= 1),
      Achievement('多產創作者', '發布 10 件作品', s.posts >= 10),
      Achievement('人氣新星', '獲得 10 位粉絲', s.followers >= 10),
      Achievement('熱心讀者', '按讚 20 件作品', s.liked >= 20),
      Achievement('話題製造機', '留言 20 次', s.comments >= 20),
      Achievement('社群之友', '追蹤 10 位創作者', s.following >= 10),
    ];
