import '../boosters/booster_def.dart';
import '../boosters/booster_rules.dart';
import '../content/level_def.dart';
import '../core/value_objects.dart';
import '../moving_lanes/moving_lane_rules.dart';
import '../moving_lanes/moving_lane_state.dart';
import 'board_rules.dart';
import 'board_state.dart';
import 'move.dart';
import 'resolution.dart';

enum ReplayCommandType {
  move,
  grabLaneProduct,
  placeHeldLaneProduct,
  useBooster,
}

final class ReplayCommand {
  const ReplayCommand({
    required this.type,
    required this.elapsedMs,
    this.move,
    this.target,
    this.payload = const <String, Object?>{},
  });

  final ReplayCommandType type;
  final int elapsedMs;
  final MoveAction? move;
  final CellAddress? target;
  final Map<String, Object?> payload;

  factory ReplayCommand.fromJson(Map<String, Object?> json) {
    final ReplayCommandType type = ReplayCommandType.values.byName(
      json['type']! as String,
    );
    final String? source = json['source'] as String?;
    final String? target = json['target'] as String?;
    return ReplayCommand(
      type: type,
      elapsedMs: json['elapsedMs']! as int,
      move: source != null && target != null && type == ReplayCommandType.move
          ? MoveAction(
              source: _cellAddressFromKey(source),
              target: _cellAddressFromKey(target),
            )
          : null,
      target: target != null && type != ReplayCommandType.move
          ? _cellAddressFromKey(target)
          : null,
      payload:
          json['payload'] as Map<String, Object?>? ?? const <String, Object?>{},
    );
  }

  Map<String, Object?> toJson() {
    final Map<String, Object?> json = <String, Object?>{
      'type': type.name,
      'elapsedMs': elapsedMs,
    };
    if (move != null) {
      json['source'] = move!.source.key;
      json['target'] = move!.target.key;
    } else if (target != null) {
      json['target'] = target!.key;
    }
    if (payload.isNotEmpty) {
      json['payload'] = payload;
    }
    return json;
  }
}

final class ReplayLog {
  ReplayLog({
    required this.levelId,
    required this.seed,
    List<ReplayCommand> commands = const <ReplayCommand>[],
  }) : commands = List<ReplayCommand>.unmodifiable(commands);

  final LevelId levelId;
  final int seed;
  final List<ReplayCommand> commands;

  factory ReplayLog.fromJson(Map<String, Object?> json) {
    final List<Object?> commandsJson =
        json['commands'] as List<Object?>? ?? const <Object?>[];
    return ReplayLog(
      levelId: json['levelId']! as String,
      seed: json['seed']! as int,
      commands: commandsJson
          .map((Object? item) {
            return ReplayCommand.fromJson(item! as Map<String, Object?>);
          })
          .toList(growable: false),
    );
  }

  ReplayLog append(ReplayCommand command) {
    return ReplayLog(
      levelId: levelId,
      seed: seed,
      commands: <ReplayCommand>[...commands, command],
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'levelId': levelId,
      'seed': seed,
      'commands': commands
          .map((ReplayCommand command) => command.toJson())
          .toList(growable: false),
    };
  }
}

final class ReplayPlaybackResult {
  ReplayPlaybackResult({
    required this.board,
    required List<MovingLaneState> lanes,
    required this.appliedCommands,
    this.invalidCommandIndex,
    this.invalidReason,
  }) : lanes = List<MovingLaneState>.unmodifiable(lanes);

  final BoardState board;
  final List<MovingLaneState> lanes;
  final int appliedCommands;
  final int? invalidCommandIndex;
  final String? invalidReason;

  bool get passed => invalidCommandIndex == null;
}

final class ReplayPlayer {
  const ReplayPlayer({
    this.boardRules = const BoardRules(),
    this.laneRules = const MovingLaneRules(),
    this.boosterRules = const BoosterRules(),
  });

  final BoardRules boardRules;
  final MovingLaneRules laneRules;
  final BoosterRules boosterRules;

  ReplayPlaybackResult play(LevelDef level, ReplayLog replay) {
    var board = boardRules.resolveBoard(level.createBoardState()).state;
    final List<MovingLaneState> lanes = level.movingLanes
        .map((lane) => MovingLaneState(def: lane))
        .toList();

    if (replay.levelId != level.id || replay.seed != level.seed) {
      return ReplayPlaybackResult(
        board: board,
        lanes: lanes,
        appliedCommands: 0,
        invalidCommandIndex: 0,
        invalidReason: 'level_mismatch',
      );
    }

    for (var index = 0; index < replay.commands.length; index += 1) {
      final ReplayCommand command = replay.commands[index];
      final _ReplayStepResult result = _applyCommand(board, lanes, command);
      if (!result.isValid) {
        return ReplayPlaybackResult(
          board: board,
          lanes: lanes,
          appliedCommands: index,
          invalidCommandIndex: index,
          invalidReason: result.invalidReason,
        );
      }
      board = result.board;
      lanes
        ..clear()
        ..addAll(result.lanes);
    }

    return ReplayPlaybackResult(
      board: board,
      lanes: lanes,
      appliedCommands: replay.commands.length,
    );
  }

  _ReplayStepResult _applyCommand(
    BoardState board,
    List<MovingLaneState> lanes,
    ReplayCommand command,
  ) {
    return switch (command.type) {
      ReplayCommandType.move => _applyMoveCommand(board, lanes, command),
      ReplayCommandType.grabLaneProduct => _applyGrabCommand(
        board,
        lanes,
        command,
      ),
      ReplayCommandType.placeHeldLaneProduct => _applyHeldPlacementCommand(
        board,
        lanes,
        command,
      ),
      ReplayCommandType.useBooster => _applyBoosterCommand(
        board,
        lanes,
        command,
      ),
    };
  }

  _ReplayStepResult _applyMoveCommand(
    BoardState board,
    List<MovingLaneState> lanes,
    ReplayCommand command,
  ) {
    final MoveAction? move = command.move;
    if (move == null) {
      return _ReplayStepResult.invalid(board, lanes, 'missing_move');
    }
    final ResolutionResult result = boardRules.applyMove(board, move);
    final InvalidMoveReason? invalidReason = result.invalidReason;
    if (invalidReason != null) {
      return _ReplayStepResult.invalid(board, lanes, invalidReason.name);
    }
    return _ReplayStepResult.valid(result.state, lanes);
  }

  _ReplayStepResult _applyGrabCommand(
    BoardState board,
    List<MovingLaneState> lanes,
    ReplayCommand command,
  ) {
    final String? laneId = command.payload['lane_id'] as String?;
    if (laneId == null) {
      return _ReplayStepResult.invalid(board, lanes, 'missing_lane_id');
    }
    final int laneIndex = lanes.indexWhere(
      (MovingLaneState lane) => lane.def.id == laneId,
    );
    if (laneIndex < 0) {
      return _ReplayStepResult.invalid(board, lanes, 'unknown_lane');
    }
    final GrabLaneProductResult result = laneRules.grabProduct(
      lanes[laneIndex],
    );
    final GrabInvalidReason? invalidReason = result.invalidReason;
    if (invalidReason != null) {
      return _ReplayStepResult.invalid(board, lanes, invalidReason.name);
    }
    final List<MovingLaneState> updated = List<MovingLaneState>.of(lanes);
    updated[laneIndex] = result.state;
    return _ReplayStepResult.valid(board, updated);
  }

  _ReplayStepResult _applyHeldPlacementCommand(
    BoardState board,
    List<MovingLaneState> lanes,
    ReplayCommand command,
  ) {
    final CellAddress? target = command.target;
    if (target == null) {
      return _ReplayStepResult.invalid(board, lanes, 'missing_target');
    }
    final int laneIndex = lanes.indexWhere(
      (MovingLaneState lane) => lane.heldProduct != null,
    );
    if (laneIndex < 0) {
      return _ReplayStepResult.invalid(board, lanes, 'missing_held_product');
    }
    final LaneHeldProduct heldProduct = lanes[laneIndex].heldProduct!;
    final ResolutionResult result = boardRules.placeProduct(
      board,
      product: heldProduct.product,
      target: target,
    );
    final InvalidMoveReason? invalidReason = result.invalidReason;
    if (invalidReason != null) {
      return _ReplayStepResult.invalid(board, lanes, invalidReason.name);
    }
    final List<MovingLaneState> updated = List<MovingLaneState>.of(lanes);
    updated[laneIndex] = laneRules.clearHeldProduct(updated[laneIndex]);
    return _ReplayStepResult.valid(result.state, updated);
  }

  _ReplayStepResult _applyBoosterCommand(
    BoardState board,
    List<MovingLaneState> lanes,
    ReplayCommand command,
  ) {
    final String? boosterName = command.payload['booster'] as String?;
    if (boosterName == null) {
      return _ReplayStepResult.invalid(board, lanes, 'missing_booster');
    }
    final BoosterKind booster = BoosterKind.values.byName(boosterName);
    final BoosterUseResult result = boosterRules.useBooster(board, booster);
    return _ReplayStepResult.valid(result.board, lanes);
  }
}

final class _ReplayStepResult {
  const _ReplayStepResult._({
    required this.board,
    required this.lanes,
    this.invalidReason,
  });

  factory _ReplayStepResult.valid(
    BoardState board,
    List<MovingLaneState> lanes,
  ) {
    return _ReplayStepResult._(
      board: board,
      lanes: List<MovingLaneState>.unmodifiable(lanes),
    );
  }

  factory _ReplayStepResult.invalid(
    BoardState board,
    List<MovingLaneState> lanes,
    String invalidReason,
  ) {
    return _ReplayStepResult._(
      board: board,
      lanes: List<MovingLaneState>.unmodifiable(lanes),
      invalidReason: invalidReason,
    );
  }

  final BoardState board;
  final List<MovingLaneState> lanes;
  final String? invalidReason;

  bool get isValid => invalidReason == null;
}

CellAddress _cellAddressFromKey(String key) {
  final List<int> parts = key
      .split(':')
      .map((String part) => int.parse(part))
      .toList(growable: false);
  if (parts.length != 3) {
    throw FormatException('Invalid cell address: $key');
  }
  return CellAddress(row: parts[0], column: parts[1], cell: parts[2]);
}
