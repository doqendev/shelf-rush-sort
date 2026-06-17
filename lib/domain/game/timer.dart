final class LevelTimer {
  const LevelTimer({
    required this.elapsed,
    required this.limit,
    this.paused = false,
  });

  factory LevelTimer.fromSeconds(int? seconds) {
    return LevelTimer(
      elapsed: Duration.zero,
      limit: seconds == null ? null : Duration(seconds: seconds),
    );
  }

  final Duration elapsed;
  final Duration? limit;
  final bool paused;

  Duration? get remaining {
    final Duration? limit = this.limit;
    if (limit == null) {
      return null;
    }
    final Duration remaining = limit - elapsed;
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  bool get expired {
    final Duration? limit = this.limit;
    return limit != null && elapsed >= limit;
  }

  LevelTimer tick(Duration delta) {
    if (paused || delta <= Duration.zero) {
      return this;
    }
    return LevelTimer(elapsed: elapsed + delta, limit: limit, paused: paused);
  }

  LevelTimer copyWith({Duration? elapsed, Duration? limit, bool? paused}) {
    return LevelTimer(
      elapsed: elapsed ?? this.elapsed,
      limit: limit ?? this.limit,
      paused: paused ?? this.paused,
    );
  }
}
