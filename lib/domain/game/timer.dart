final class LevelTimer {
  const LevelTimer({
    required this.elapsed,
    required this.limit,
    this.paused = false,
    this.frozenRemaining = Duration.zero,
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
  final Duration frozenRemaining;

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

  bool get frozen => frozenRemaining > Duration.zero;

  LevelTimer tick(Duration delta) {
    if (paused || delta <= Duration.zero) {
      return this;
    }
    if (frozen) {
      final Duration remaining = frozenRemaining - delta;
      return copyWith(
        frozenRemaining: remaining.isNegative ? Duration.zero : remaining,
      );
    }
    return LevelTimer(elapsed: elapsed + delta, limit: limit, paused: paused);
  }

  LevelTimer freeze(Duration duration) {
    if (duration <= Duration.zero) {
      return this;
    }
    return copyWith(frozenRemaining: frozenRemaining + duration);
  }

  LevelTimer copyWith({
    Duration? elapsed,
    Duration? limit,
    bool? paused,
    Duration? frozenRemaining,
  }) {
    return LevelTimer(
      elapsed: elapsed ?? this.elapsed,
      limit: limit ?? this.limit,
      paused: paused ?? this.paused,
      frozenRemaining: frozenRemaining ?? this.frozenRemaining,
    );
  }
}
