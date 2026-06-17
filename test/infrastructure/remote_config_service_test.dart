import 'package:flutter_test/flutter_test.dart';
import 'package:shelf_rush_sort/domain/content/level_def.dart';
import 'package:shelf_rush_sort/domain/content/remote_config_def.dart';
import 'package:shelf_rush_sort/domain/game/objective.dart';
import 'package:shelf_rush_sort/domain/moving_lanes/moving_lane_def.dart';
import 'package:shelf_rush_sort/infrastructure/remote_config/remote_config_service.dart';

void main() {
  test('applies lane speed multiplier without mutating authored level', () {
    final LevelDef level = _laneLevel(speed: 1.25);
    const double multiplier = 1.4;
    final RemoteConfigService service = RemoteConfigService(
      RemoteConfigDef(
        firstInterstitialLevel: 8,
        adCooldownSeconds: 180,
        laneSpeedMultiplier: multiplier,
        featureFlags: const <String, bool>{'shop': true},
      ),
    );

    final LevelDef adjusted = service.applyToLevel(level);

    expect(adjusted, isNot(same(level)));
    expect(adjusted.movingLanes.single.speedCellsPerSecond, 1.25 * multiplier);
    expect(level.movingLanes.single.speedCellsPerSecond, 1.25);
    expect(adjusted.movingLanes.single.queue, level.movingLanes.single.queue);
  });

  test('returns authored level when lane multiplier is neutral', () {
    final LevelDef level = _laneLevel(speed: 1.25);
    final RemoteConfigService service = RemoteConfigService(
      RemoteConfigDef(
        firstInterstitialLevel: 8,
        adCooldownSeconds: 180,
        laneSpeedMultiplier: 1,
        featureFlags: const <String, bool>{},
      ),
    );

    expect(service.applyToLevel(level), same(level));
  });

  test('reads feature flags from defaults', () {
    final RemoteConfigService service = RemoteConfigService(
      RemoteConfigDef(
        firstInterstitialLevel: 8,
        adCooldownSeconds: 180,
        laneSpeedMultiplier: 1,
        featureFlags: const <String, bool>{'shop': true},
      ),
    );

    expect(service.isEnabled('shop'), isTrue);
    expect(service.isEnabled('unknown'), isFalse);
  });
}

LevelDef _laneLevel({required double speed}) {
  return LevelDef(
    id: 'level_remote',
    levelNumber: 15,
    title: 'Remote Config Test',
    seed: 15,
    objective: ObjectiveRequirement(type: ObjectiveType.clearAll),
    compartments: <CompartmentDef>[
      for (var index = 0; index < 15; index += 1)
        CompartmentDef(
          index: index,
          locked: true,
          cells: const <String?>[null, null, null],
        ),
    ],
    movingLanes: <MovingLaneDef>[
      MovingLaneDef(
        id: 'lane_main',
        orientation: LaneOrientation.horizontal,
        behavior: LaneBehavior.finite,
        speedCellsPerSecond: speed,
        queue: const <MovingLaneProductDef>[
          MovingLaneProductDef(skuId: 'sku_000', travelTimeMs: 5000),
        ],
      ),
    ],
  );
}
