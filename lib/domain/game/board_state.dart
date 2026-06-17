import '../blockers/blocker_def.dart';
import '../core/value_objects.dart';
import 'hidden_preview.dart';

final class HiddenPreviewLayerState {
  HiddenPreviewLayerState({
    required List<SkuId?> cells,
    this.previewMode = HiddenPreviewMode.exactDim,
  }) : assert(cells.length == cellsPerCompartment),
       cells = List<SkuId?>.unmodifiable(cells);

  final List<SkuId?> cells;
  final HiddenPreviewMode previewMode;
}

final class ProductInstance {
  const ProductInstance({
    required this.id,
    required this.skuId,
    this.selectable = true,
    this.blocker = BlockerKind.none,
  });

  final ProductInstanceId id;
  final SkuId skuId;
  final bool selectable;
  final BlockerKind blocker;

  bool get isBlocked => blocker != BlockerKind.none;

  ProductInstance copyWith({
    ProductInstanceId? id,
    SkuId? skuId,
    bool? selectable,
    BlockerKind? blocker,
  }) {
    return ProductInstance(
      id: id ?? this.id,
      skuId: skuId ?? this.skuId,
      selectable: selectable ?? this.selectable,
      blocker: blocker ?? this.blocker,
    );
  }
}

final class ShelfCell {
  const ShelfCell({this.product, this.blocker = BlockerKind.none});

  const ShelfCell.empty({this.blocker = BlockerKind.none}) : product = null;

  final ProductInstance? product;
  final BlockerKind blocker;

  bool get isEmpty => product == null;
  bool get isOccupied => product != null;
  bool get isBlocked => blocker != BlockerKind.none;

  ShelfCell withProduct(ProductInstance product) {
    return ShelfCell(product: product, blocker: blocker);
  }

  ShelfCell withoutProduct() {
    return ShelfCell.empty(blocker: blocker);
  }
}

final class CompartmentState {
  CompartmentState({
    required this.index,
    required List<ShelfCell> frontCells,
    List<ProductInstance> hiddenStack = const <ProductInstance>[],
    List<HiddenPreviewLayerState> hiddenPreviewLayers =
        const <HiddenPreviewLayerState>[],
    this.locked = false,
    this.decorative = false,
    this.clearedCount = 0,
    this.hiddenPreviewRevealed = false,
  }) : assert(frontCells.length == cellsPerCompartment),
       frontCells = List<ShelfCell>.unmodifiable(frontCells),
       hiddenStack = List<ProductInstance>.unmodifiable(hiddenStack),
       hiddenPreviewLayers = List<HiddenPreviewLayerState>.unmodifiable(
         hiddenPreviewLayers,
       );

  final int index;
  final List<ShelfCell> frontCells;
  final List<ProductInstance> hiddenStack;
  final List<HiddenPreviewLayerState> hiddenPreviewLayers;
  final bool locked;
  final bool decorative;
  final int clearedCount;
  final bool hiddenPreviewRevealed;

  bool get interactable => !locked && !decorative;
  bool get hasHiddenProducts => hiddenStack.isNotEmpty;
  HiddenPreviewLayerState? get currentHiddenPreviewLayer =>
      hiddenPreviewLayers.isEmpty ? null : hiddenPreviewLayers.first;
  HiddenPreviewMode get hiddenPreviewMode {
    if (hiddenPreviewRevealed) {
      return HiddenPreviewMode.exactDim;
    }
    return currentHiddenPreviewLayer?.previewMode ?? HiddenPreviewMode.hidden;
  }

  List<SkuId?> get hiddenPreviewCells {
    final HiddenPreviewLayerState? layer = currentHiddenPreviewLayer;
    if (layer != null) {
      return layer.cells;
    }
    if (hiddenStack.isEmpty) {
      return const <SkuId?>[];
    }
    return <SkuId?>[
      for (var index = 0; index < cellsPerCompartment; index += 1)
        index < hiddenStack.length ? hiddenStack[index].skuId : null,
    ];
  }

  CellAddress addressForCell(int cell) {
    return CellAddress.fromCompartmentIndex(index, cell);
  }

  ShelfCell cellAt(int cell) => frontCells[cell];

  CompartmentState replaceCell(int cell, ShelfCell shelfCell) {
    final List<ShelfCell> updated = List<ShelfCell>.of(frontCells);
    updated[cell] = shelfCell;
    return copyWith(frontCells: updated);
  }

  CompartmentState copyWith({
    List<ShelfCell>? frontCells,
    List<ProductInstance>? hiddenStack,
    List<HiddenPreviewLayerState>? hiddenPreviewLayers,
    bool? locked,
    bool? decorative,
    int? clearedCount,
    bool? hiddenPreviewRevealed,
  }) {
    return CompartmentState(
      index: index,
      frontCells: frontCells ?? this.frontCells,
      hiddenStack: hiddenStack ?? this.hiddenStack,
      hiddenPreviewLayers: hiddenPreviewLayers ?? this.hiddenPreviewLayers,
      locked: locked ?? this.locked,
      decorative: decorative ?? this.decorative,
      clearedCount: clearedCount ?? this.clearedCount,
      hiddenPreviewRevealed:
          hiddenPreviewRevealed ?? this.hiddenPreviewRevealed,
    );
  }
}

final class BoardState {
  BoardState({
    required this.levelId,
    required List<CompartmentState> compartments,
    this.levelEnded = false,
  }) : assert(compartments.length == compartmentCount),
       compartments = List<CompartmentState>.unmodifiable(compartments);

  final LevelId levelId;
  final List<CompartmentState> compartments;
  final bool levelEnded;

  CompartmentState compartmentAtIndex(int index) => compartments[index];

  CompartmentState compartmentAtAddress(CellAddress address) {
    return compartments[address.compartmentIndex];
  }

  ShelfCell? cellAt(CellAddress address) {
    if (address.compartmentIndex < 0 ||
        address.compartmentIndex >= compartments.length) {
      return null;
    }
    return compartments[address.compartmentIndex].frontCells[address.cell];
  }

  ProductInstance? productAt(CellAddress address) {
    return cellAt(address)?.product;
  }

  BoardState replaceCell(CellAddress address, ShelfCell shelfCell) {
    final CompartmentState compartment = compartmentAtAddress(address);
    return replaceCompartment(compartment.replaceCell(address.cell, shelfCell));
  }

  BoardState replaceCompartment(CompartmentState compartment) {
    final List<CompartmentState> updated = List<CompartmentState>.of(
      compartments,
    );
    updated[compartment.index] = compartment;
    return copyWith(compartments: updated);
  }

  BoardState copyWith({
    List<CompartmentState>? compartments,
    bool? levelEnded,
  }) {
    return BoardState(
      levelId: levelId,
      compartments: compartments ?? this.compartments,
      levelEnded: levelEnded ?? this.levelEnded,
    );
  }

  Iterable<ProductInstance> get visibleProducts sync* {
    for (final CompartmentState compartment in compartments) {
      for (final ShelfCell cell in compartment.frontCells) {
        final ProductInstance? product = cell.product;
        if (product != null) {
          yield product;
        }
      }
    }
  }

  int get visibleProductCount => visibleProducts.length;

  String get stableHash {
    final StringBuffer buffer = StringBuffer(levelId)..write('|');
    for (final CompartmentState compartment in compartments) {
      buffer
        ..write(compartment.index)
        ..write(':')
        ..write(compartment.locked ? 'L' : 'U')
        ..write(compartment.decorative ? 'D' : 'I')
        ..write(compartment.hiddenPreviewRevealed ? 'R' : 'H')
        ..write(compartment.hiddenPreviewMode.name)
        ..write(':');
      for (final ShelfCell cell in compartment.frontCells) {
        buffer
          ..write(cell.blocker.name)
          ..write('/')
          ..write(cell.product?.id ?? '-')
          ..write('/')
          ..write(cell.product?.skuId ?? '-')
          ..write('/')
          ..write(cell.product?.blocker.name ?? '-')
          ..write(',');
      }
      buffer.write(':');
      for (final ProductInstance product in compartment.hiddenStack) {
        buffer
          ..write(product.id)
          ..write('/')
          ..write(product.skuId)
          ..write(',');
      }
      buffer.write(':');
      for (final SkuId? skuId in compartment.hiddenPreviewCells) {
        buffer
          ..write(skuId ?? '-')
          ..write(',');
      }
      buffer.write('|');
    }
    buffer.write(levelEnded ? 'ended' : 'open');
    return _hashString(buffer.toString());
  }

  int get emptyInteractableCellCount {
    var total = 0;
    for (final CompartmentState compartment in compartments) {
      if (!compartment.interactable) {
        continue;
      }
      total += compartment.frontCells.where((ShelfCell cell) {
        return cell.isEmpty && !cell.isBlocked;
      }).length;
    }
    return total;
  }

  static String _hashString(String value) {
    var hash = 17;
    for (final int codeUnit in value.codeUnits) {
      hash = 37 * hash + codeUnit;
    }
    return hash.toUnsigned(32).toRadixString(16);
  }
}
