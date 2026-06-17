final class SeededRandom {
  SeededRandom(int seed) : _state = seed & _mask;

  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;
  static const int _mask = 0x7fffffff;

  int _state;

  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', 'Must be positive.');
    }
    _state = ((_state * _multiplier) + _increment) & _mask;
    return _state % max;
  }

  double nextDouble() => nextInt(_mask) / _mask;

  T choose<T>(List<T> values) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'Must not be empty.');
    }
    return values[nextInt(values.length)];
  }
}
