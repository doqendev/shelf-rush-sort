import 'package:flutter/material.dart';

import '../../../application/game_session/game_session_state.dart';
import '../../../domain/game/objective.dart';
import '../../../infrastructure/save/save_repository.dart';

final class HudOverlay extends StatelessWidget {
  const HudOverlay({
    super.key,
    required this.session,
    required this.save,
    required this.onMap,
    required this.onShop,
    required this.onSettings,
    required this.onRetry,
    this.onDebug,
  });

  final GameSessionState session;
  final PlayerSave save;
  final VoidCallback onMap;
  final VoidCallback onShop;
  final VoidCallback onSettings;
  final VoidCallback onRetry;
  final VoidCallback? onDebug;

  @override
  Widget build(BuildContext context) {
    final Duration? remaining = session.timer.remaining;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              _StatusPill(
                icon: Icons.flag,
                label: 'L${session.level.levelNumber}',
              ),
              const SizedBox(width: 8),
              _StatusPill(
                icon: Icons.swap_horiz,
                label: '${session.moveCount}',
              ),
              const SizedBox(width: 8),
              _StatusPill(icon: Icons.paid, label: '${save.coins}'),
              const SizedBox(width: 8),
              Flexible(
                child: _StatusPill(
                  icon: Icons.task_alt,
                  label: _objectiveLabel(),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: 'Map',
                onPressed: onMap,
                icon: const Icon(Icons.map_outlined),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Shop',
                onPressed: onShop,
                icon: const Icon(Icons.storefront),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                tooltip: 'Settings',
                onPressed: onSettings,
                icon: const Icon(Icons.settings),
              ),
              if (onDebug != null) ...<Widget>[
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Debug',
                  onPressed: onDebug,
                  icon: const Icon(Icons.analytics_outlined),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  value: _progressValue(),
                  backgroundColor: Colors.white.withValues(alpha: 0.74),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(
                icon: Icons.timer_outlined,
                label: remaining == null ? '--' : '${remaining.inSeconds}s',
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Retry',
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          if (session.laneHoldingProduct != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF2E4450),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    session.laneHoldingProduct!.heldProduct!.product.skuId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_laneWarningLabel() != null) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: _StatusPill(
                icon: Icons.warning_amber,
                label: _laneWarningLabel()!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _objectiveLabel() {
    final objective = session.objective;
    switch (objective.requirement.type) {
      case ObjectiveType.clearAll:
        return 'Clear all';
      case ObjectiveType.clearSkuTargets:
        final int remaining = objective.remainingTargets.values.fold<int>(
          0,
          (int sum, int count) => sum + count.clamp(0, 999).toInt(),
        );
        return 'Order $remaining';
      case ObjectiveType.clearCategoryTargets:
        return 'Categories';
      case ObjectiveType.clearSpecialTargets:
        return 'Specials';
      case ObjectiveType.comboTarget:
        return 'Combo ${objective.maxCombo}/${objective.requirement.comboTarget}';
      case ObjectiveType.timeChallenge:
        return 'Time run';
      case ObjectiveType.laneDeliveryTarget:
        return 'Lane ${objective.laneDeliveredProducts}/${objective.requirement.laneDeliveryTarget}';
    }
  }

  String? _laneWarningLabel() {
    for (final lane in session.lanes) {
      if (lane.currentProductDef != null &&
          !lane.exhausted &&
          lane.currentProgress >= 0.72) {
        return 'Lane expiring';
      }
    }
    return null;
  }

  double _progressValue() {
    final int initial = session.objective.initialVisibleProducts;
    if (initial == 0) {
      return 1;
    }
    return (session.objective.clearedProducts / initial).clamp(0, 1);
  }
}

final class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x2235261E)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 17),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
