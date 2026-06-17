typedef SkuId = String;
typedef ProductInstanceId = String;
typedef LevelId = String;
typedef PlayerId = String;

const int boardRows = 5;
const int boardColumns = 3;
const int cellsPerCompartment = 3;
const int compartmentCount = boardRows * boardColumns;
const int frontCellCount = compartmentCount * cellsPerCompartment;

// Canonical board geometry for normal gameplay. Do not make this rack shape
// remote-configurable; level and UI systems should adapt around the 5x3 rack.
const int minInteractiveTargetPx = 44;

enum ProductShape { bottle, box, can, pouch, jar, carton, toy, produce }

final class CellAddress implements Comparable<CellAddress> {
  const CellAddress({
    required this.row,
    required this.column,
    required this.cell,
  }) : assert(row >= 0 && row < boardRows),
       assert(column >= 0 && column < boardColumns),
       assert(cell >= 0 && cell < cellsPerCompartment);

  factory CellAddress.fromCompartmentIndex(int compartmentIndex, int cell) {
    if (compartmentIndex < 0 || compartmentIndex >= compartmentCount) {
      throw ArgumentError.value(
        compartmentIndex,
        'compartmentIndex',
        'Out of board range.',
      );
    }
    return CellAddress(
      row: compartmentIndex ~/ boardColumns,
      column: compartmentIndex % boardColumns,
      cell: cell,
    );
  }

  final int row;
  final int column;
  final int cell;

  int get compartmentIndex => row * boardColumns + column;

  String get key => '$row:$column:$cell';

  @override
  int compareTo(CellAddress other) {
    final int compartmentCompare = compartmentIndex.compareTo(
      other.compartmentIndex,
    );
    if (compartmentCompare != 0) {
      return compartmentCompare;
    }
    return cell.compareTo(other.cell);
  }

  @override
  bool operator ==(Object other) {
    return other is CellAddress &&
        row == other.row &&
        column == other.column &&
        cell == other.cell;
  }

  @override
  int get hashCode => Object.hash(row, column, cell);

  @override
  String toString() => 'CellAddress($row, $column, $cell)';
}
