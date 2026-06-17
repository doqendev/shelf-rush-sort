final class ComboState {
  const ComboState({this.count = 0});

  final int count;

  ComboState onClear() => ComboState(count: count + 1);

  ComboState reset() => const ComboState();
}
