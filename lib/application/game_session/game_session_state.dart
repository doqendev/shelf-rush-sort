import '../../domain/content/level_def.dart';
import '../../domain/core/value_objects.dart';
import '../../domain/game/board_state.dart';
import '../../domain/game/fail_reason.dart';
import '../../domain/game/move.dart';
import '../../domain/game/objective.dart';
import '../../domain/game/replay.dart';
import '../../domain/game/timer.dart';
import '../../domain/moving_lanes/moving_lane_state.dart';

enum GameSessionStatus { loading, playing, won, failed }

enum SessionEventType {
  selectionChanged,
  invalidMove,
  moveApplied,
  tripleCleared,
  hiddenRevealed,
  laneGrabbed,
  laneMissed,
  boosterUsed,
  revived,
  levelWon,
  levelFailed,
}

final class SessionEvent {
  SessionEvent({
    required this.type,
    Map<String, Object?> payload = const <String, Object?>{},
  }) : payload = Map<String, Object?>.unmodifiable(payload);

  final SessionEventType type;
  final Map<String, Object?> payload;
}

final class GameSessionState {
  GameSessionState({
    required this.level,
    required this.board,
    required this.objective,
    required this.timer,
    required this.replay,
    required List<MovingLaneState> lanes,
    this.status = GameSessionStatus.playing,
    this.selectedCell,
    this.moveCount = 0,
    this.lastInvalidReason,
    this.failReason = LevelFailReason.none,
    List<SessionEvent> events = const <SessionEvent>[],
  }) : lanes = List<MovingLaneState>.unmodifiable(lanes),
       events = List<SessionEvent>.unmodifiable(events);

  final LevelDef level;
  final BoardState board;
  final ObjectiveState objective;
  final LevelTimer timer;
  final ReplayLog replay;
  final List<MovingLaneState> lanes;
  final GameSessionStatus status;
  final CellAddress? selectedCell;
  final int moveCount;
  final InvalidMoveReason? lastInvalidReason;
  final LevelFailReason failReason;
  final List<SessionEvent> events;

  bool get isEnded {
    return status == GameSessionStatus.won ||
        status == GameSessionStatus.failed;
  }

  MovingLaneState? laneById(String laneId) {
    for (final MovingLaneState lane in lanes) {
      if (lane.def.id == laneId) {
        return lane;
      }
    }
    return null;
  }

  MovingLaneState? get laneHoldingProduct {
    for (final MovingLaneState lane in lanes) {
      if (lane.heldProduct != null) {
        return lane;
      }
    }
    return null;
  }

  GameSessionState copyWith({
    BoardState? board,
    ObjectiveState? objective,
    LevelTimer? timer,
    ReplayLog? replay,
    List<MovingLaneState>? lanes,
    GameSessionStatus? status,
    CellAddress? selectedCell,
    bool clearSelectedCell = false,
    int? moveCount,
    InvalidMoveReason? lastInvalidReason,
    bool clearInvalidReason = false,
    LevelFailReason? failReason,
    List<SessionEvent>? events,
  }) {
    return GameSessionState(
      level: level,
      board: board ?? this.board,
      objective: objective ?? this.objective,
      timer: timer ?? this.timer,
      replay: replay ?? this.replay,
      lanes: lanes ?? this.lanes,
      status: status ?? this.status,
      selectedCell: clearSelectedCell
          ? null
          : selectedCell ?? this.selectedCell,
      moveCount: moveCount ?? this.moveCount,
      lastInvalidReason: clearInvalidReason
          ? null
          : lastInvalidReason ?? this.lastInvalidReason,
      failReason: failReason ?? this.failReason,
      events: events ?? this.events,
    );
  }
}
