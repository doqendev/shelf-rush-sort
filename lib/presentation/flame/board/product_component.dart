import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';

import '../../../domain/content/product_def.dart';
import '../../../domain/core/value_objects.dart';
import '../input/input_router.dart';

final class ProductComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  ProductComponent({
    required this.address,
    required this.productDef,
    required this.inputRouter,
    required this.selected,
    required super.position,
    required super.size,
  });

  final CellAddress address;
  final ProductDef productDef;
  final InputRouter inputRouter;
  final bool selected;
  Vector2? _lastDragCanvasPosition;

  @override
  void onTapDown(TapDownEvent event) {
    inputRouter.onProductTapped(address);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    _lastDragCanvasPosition = event.canvasPosition;
    inputRouter.onProductDragStart(address);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    _lastDragCanvasPosition = event.canvasEndPosition;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final Vector2? canvasPosition = _lastDragCanvasPosition;
    if (canvasPosition != null) {
      inputRouter.onProductDragEnd(canvasPosition);
    }
    _lastDragCanvasPosition = null;
  }

  @override
  void render(Canvas canvas) {
    final Rect rect = size.toRect();
    final Color color = _parseColor(productDef.colorHex);
    final Paint shadow = Paint()..color = const Color(0x33000000);
    canvas.drawOval(rect.deflate(4).translate(0, rect.height * 0.16), shadow);
    final Paint body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.lerp(color, const Color(0xFFFFFFFF), 0.34)!,
          color,
        ],
      ).createShader(rect);
    final RRect bodyRect = RRect.fromRectAndRadius(
      rect.deflate(selected ? 2 : 5),
      Radius.circular(_radiusForShape(productDef.shape)),
    );
    canvas.drawRRect(bodyRect, body);
    final Paint shine = Paint()..color = const Color(0x55FFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.width * 0.22,
          rect.height * 0.14,
          rect.width * 0.22,
          rect.height * 0.18,
        ),
        const Radius.circular(8),
      ),
      shine,
    );
    if (selected) {
      final Paint selectedPaint = Paint()
        ..color = const Color(0xFF1D7F5A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(bodyRect, selectedPaint);
    }
    final String label = productDef.displayName
        .split(' ')
        .map((String part) => part.isEmpty ? '' : part.substring(0, 1))
        .take(2)
        .join();
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _contrastingTextColor(color),
          fontSize: rect.height * 0.26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset((rect.width - painter.width) / 2, rect.height * 0.36),
    );
  }

  double _radiusForShape(ProductShape shape) {
    switch (shape) {
      case ProductShape.bottle:
      case ProductShape.can:
      case ProductShape.jar:
        return 14;
      case ProductShape.pouch:
      case ProductShape.produce:
        return 18;
      case ProductShape.box:
      case ProductShape.carton:
      case ProductShape.toy:
        return 8;
    }
  }

  Color _parseColor(String hex) {
    final String normalized = hex.replaceFirst('#', '');
    return Color(int.parse('FF$normalized', radix: 16));
  }

  Color _contrastingTextColor(Color color) {
    return color.computeLuminance() > 0.52
        ? const Color(0xFF35261E)
        : const Color(0xFFFFFFFF);
  }
}
