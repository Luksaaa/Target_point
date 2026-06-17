import 'dart:math' as math;
import 'dart_hit.dart';

class PlayerScore {
  const PlayerScore({
    this.userId,
    required this.name,
    required this.avatarColorValue,
    required this.remaining,
    required this.totalScored,
    required this.turns,
    required this.isWinner,
    this.photoUrl,
    this.stats = const {},
  });

  final String? userId;
  final String name;
  final int avatarColorValue; // Hex ARGB representation
  final String? photoUrl;
  final int remaining;
  final int totalScored;
  final List<List<DartHit>> turns;
  final bool isWinner;
  final Map<String, int> stats;

  bool get isRegisteredUser => userId != null && userId!.isNotEmpty;

  double get average {
    if (totalThrows == 0) return 0.0;
    return (totalScored / totalThrows) * 3;
  }

  int get highestTurnScore {
    if (turns.isEmpty) return 0;
    return turns
        .map((t) => t.fold<int>(0, (sum, hit) => sum + hit.score))
        .reduce(math.max);
  }

  int get count180s {
    return turns
        .where((t) => t.fold<int>(0, (sum, hit) => sum + hit.score) == 180)
        .length;
  }

  int get count140plus {
    return turns.where((t) {
      final s = t.fold<int>(0, (sum, hit) => sum + hit.score);
      return s >= 140 && s < 180;
    }).length;
  }

  int get count100plus {
    return turns.where((t) {
      final s = t.fold<int>(0, (sum, hit) => sum + hit.score);
      return s >= 100 && s < 140;
    }).length;
  }

  int get totalThrows => turns.expand((t) => t).length;

  int get doubleHits => turns
      .expand((t) => t)
      .where(
        (hit) => hit.band == SegmentBand.double || hit.band == SegmentBand.bull,
      )
      .length;

  int get tripleHits => turns
      .expand((t) => t)
      .where((hit) => hit.band == SegmentBand.triple)
      .length;

  Map<int, int> get numberHitCounts {
    final counts = <int, int>{};
    for (final hit in turns.expand((turn) => turn)) {
      final number = hit.number;
      if (number == null || hit.isMiss) {
        continue;
      }
      counts[number] = (counts[number] ?? 0) + 1;
    }
    return counts;
  }

  int? get bestNumber {
    final counts = numberHitCounts;
    if (counts.isEmpty) {
      return null;
    }

    return counts.entries.reduce((best, next) {
      if (next.value > best.value) {
        return next;
      }
      if (next.value == best.value && next.key > best.key) {
        return next;
      }
      return best;
    }).key;
  }

  int get bestNumberHits {
    final number = bestNumber;
    if (number == null) {
      return 0;
    }
    return numberHitCounts[number] ?? 0;
  }

  PlayerScore copyWith({
    String? userId,
    String? name,
    int? avatarColorValue,
    String? photoUrl,
    int? remaining,
    int? totalScored,
    List<List<DartHit>>? turns,
    bool? isWinner,
    Map<String, int>? stats,
  }) {
    return PlayerScore(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      photoUrl: photoUrl ?? this.photoUrl,
      remaining: remaining ?? this.remaining,
      totalScored: totalScored ?? this.totalScored,
      turns: turns ?? this.turns,
      isWinner: isWinner ?? this.isWinner,
      stats: stats ?? this.stats,
    );
  }
}
