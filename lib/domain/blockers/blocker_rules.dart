import 'blocker_def.dart';

final class BlockerRules {
  const BlockerRules();

  bool blocksSelection(BlockerKind blocker) {
    return blocker == BlockerKind.locked ||
        blocker == BlockerKind.tape ||
        blocker == BlockerKind.frozen ||
        blocker == BlockerKind.frost ||
        blocker == BlockerKind.cover ||
        blocker == BlockerKind.crate;
  }

  bool blocksPlacement(BlockerKind blocker) {
    return blocker == BlockerKind.locked ||
        blocker == BlockerKind.cover ||
        blocker == BlockerKind.crate;
  }
}
