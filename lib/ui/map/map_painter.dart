import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapdemo/data/models/geometry_decoding.dart';
import 'package:mapdemo/data/models/vector_tile.pb.dart';
import 'package:mapdemo/ui/map/interactivity.dart';

typedef TileResolver = Tile Function(int zoom, int col, int row);

Offset rotatePoint(Offset o, double ang) => Offset(
      o.dx * cos(ang) - o.dy * sin(ang),
      o.dy * cos(ang) + o.dx * sin(ang),
    );
Rect transformRotate(Rect r, double a) {
  final r1 = Rect.fromPoints(
    rotatePoint(r.topLeft, -a),
    rotatePoint(r.bottomRight, -a),
  );
  final r2 = Rect.fromPoints(
    rotatePoint(r.bottomLeft, -a),
    rotatePoint(r.topRight, -a),
  );
  final r3 = Rect.fromPoints(
    rotatePoint(r.topLeft, a),
    rotatePoint(r.bottomRight, a),
  );
  final r4 = Rect.fromPoints(
    rotatePoint(r.bottomLeft, a),
    rotatePoint(r.topRight, a),
  );
  return r.expandToInclude(r1).expandToInclude(r2).expandToInclude(r3).expandToInclude(r4);
}

class MapPainter extends CustomPainter {
  final Position _position;
  final TileResolver _resolveTile;

  MapPainter({required Position position, required TileResolver resolver})
      : _position = position,
        _resolveTile = resolver;

  Paint get outlinePaint => Paint()
    ..color = Colors.white
    ..strokeWidth = scaleFactor * 20.0
    ..style = PaintingStyle.stroke;

  static const backgroundColor = Color(0xff0f1a20);

  Paint get boundPaint => Paint()
    ..color = backgroundColor
    ..strokeWidth = scaleFactor * 2.0
    ..style = PaintingStyle.stroke;

  Paint get fillPaint => Paint()
    ..color = Colors.blueGrey.withOpacity(.1)
    ..style = PaintingStyle.fill;

  double get zoom => (_position.zoom - 1.0).clamp(0, 14);
  int get zoomLevel => zoom.floor();
  int get gridSize => pow(2, zoomLevel).toInt();
  double get tileSize => 1024.0;
  double get scale => zoom % 1 + 1;

  double get scaleFactor => 1 / scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(boundPaint);

    final center = Offset(size.width / 2, size.height / 2);
    final pan = Offset(-_position.pan.dx, -_position.pan.dy) * pow(2, zoomLevel).toDouble();
    final offset = -pan + center;

    canvas.save();

    canvas.translate(center.dx, center.dy);
    canvas.rotate(_position.angle);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);
    canvas.translate(offset.dx, offset.dy);

    // bbox size
    final w = size.width;
    final h = size.height;

    // define bbox to be centered
    Rect bounds = Rect.fromLTWH(-w / 2, -h / 2, w, h);

    // transform bbox to include rotated areas
    bounds = transformRotate(bounds, _position.angle);

    // translate bbox to position
    bounds = bounds.shift(Offset(-offset.dx + w / 2, -offset.dy + h / 2));

    final minRow = max((bounds.top / tileSize).floor(), 0);
    final minCol = max((bounds.left / tileSize).floor(), 0);
    final maxRow = min(minRow + ((bounds.bottom - bounds.top) / tileSize).ceil() + 1, gridSize);
    final maxCol = min(minCol + ((bounds.right - bounds.left) / tileSize).ceil() + 1, gridSize);

    int drawCount = 0;

    for (int row = minRow; row < maxRow; row++) {
      for (int col = minCol; col < maxCol; col++) {
        // 0.5 * (pow(2, zoomLevel) - 1) * -tileSize;
        paintTile(canvas, col, row);

        drawCount++;
      }
    }

    // bbox debug
    // final p1 = Paint()
    //   ..color = Colors.green.withOpacity(.5)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 2 * scaleFactor;
    // canvas.drawRect(bounds, p1);
    // canvas.drawLine(bounds.topLeft, bounds.bottomRight, p1);
    // canvas.drawLine(bounds.topRight, bounds.bottomLeft, p1);
    // end

    canvas.restore();

    final text = TextPainter(
      text: TextSpan(
        text: "Tiles: $drawCount\nZoom: $zoomLevel\nScale: $scale\nx: ${pan.dx.toStringAsFixed(2)}, y: ${pan.dy.toStringAsFixed(2)}",
        style: const TextStyle(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    );
    text.layout();
    text.paint(canvas, Offset(size.width / 2 - text.width / 2, size.height - text.height - 50));
  }

  void paintTile(Canvas canvas, int col, int row) async {
    final double left = (col * tileSize);
    final double top = (row * tileSize);
    final box = Rect.fromLTWH(left, top, tileSize, tileSize);
    canvas.drawRect(box, Paint()..color = backgroundColor);
    canvas.drawRect(box, boundPaint..strokeWidth = scaleFactor);

    final tile = _resolveTile(zoomLevel, col, row);

    for (final layer in tile.layers) {
      final pixelsPerTileUnit = 1 / layer.extent * tileSize;

      canvas.save();
      canvas.translate(left, top);
      canvas.scale(pixelsPerTileUnit);

      for (final feature in layer.features) {
        if (feature.type == Tile_GeomType.POLYGON) {
          for (final poly in decodePolygons(feature.geometry)) {
            canvas.drawPath(poly.path, fillPaint);
          }
        } else if (feature.type == Tile_GeomType.LINESTRING) {
          for (final line in decodeLineStrings(feature.geometry)) {
            canvas.drawPath(line.path, outlinePaint..strokeWidth = 5);
          }
        } else if (feature.type == Tile_GeomType.POINT) {
          for (final point in decodePoints(feature.geometry)) {
            canvas.drawCircle(Offset(point.x, point.y), 2, fillPaint);
          }
        }
      }

      canvas.restore();
    }

    // Debug paint

    final text = TextPainter(
      text: TextSpan(
        text: "Tile $zoomLevel/$col/$row",
        style: TextStyle(
          color: Colors.grey,
          fontSize: scaleFactor * 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    text.layout();
    text.paint(canvas, Offset(left + scaleFactor * 10, top + scaleFactor * 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
