import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mapdemo/data/models/geometry_decoding.dart';
import 'package:mapdemo/data/models/vector_tile.pb.dart';
import 'package:mapdemo/ui/map/interactivity.dart';

typedef TileResolver = Tile Function(int zoom, int col, int row);

// TODO: Optimize performance
class MapPainter extends CustomPainter {
  final Position _position;
  final TileResolver _resolveTile;

  MapPainter({required Position position, required TileResolver resolver})
      : _position = position,
        _resolveTile = resolver;

  Paint get outlinePaint => Paint()
    ..color = Colors.red
    ..strokeWidth = scaleFactor * 20.0
    ..style = PaintingStyle.stroke;

  static const backgroundColor = Color(0xfffffffc);

  Paint get boundPaint => Paint()
    ..color = backgroundColor
    ..strokeWidth = scaleFactor * 10.0
    ..style = PaintingStyle.stroke;

  Paint get fillPaint => Paint()
    ..color = Colors.green.shade50
    ..style = PaintingStyle.fill;

  double get zoomLevel => _position.zoom - 1;
  double get gridSize => zoomLevel * zoomLevel;
  double get tileSize => 256.0;
  double get scale => (_position.zoom % 1) + 1;

  double get scaleFactor => 1 / scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPaint(boundPaint);

    final cx = size.width / 2;
    final cy = size.width / 2;
    final dx = -_position.pan.dx - cx;
    final dy = -_position.pan.dy - cy;
    final bx = (-_position.pan.dx - cx) / scale;
    final by = (-_position.pan.dy - cy) / scale;

    canvas.save();

    // canvas.rotate(_position.angle);

    canvas.translate(-dx, -dy);
    canvas.scale(scale);

    final bounds = Rectangle<double>.fromPoints(Point(bx, by), Point(bx + size.width / scale, by + size.height / scale));

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final double top = (row * tileSize).toDouble();
        final double left = (col * tileSize).toDouble();
        final box = Rectangle(
          left,
          top,
          tileSize,
          tileSize,
        );
        // bbox debug
        // canvas.drawRect(Rect.fromLTWH(box.left, box.top, box.width, box.height), Paint()..color = Colors.green.withOpacity(.5));
        if (!bounds.intersects(box)) continue;
        paintTile(canvas, zoomLevel.floor(), col, row);
        // bbox debug
        // canvas.drawRect(Rect.fromLTWH(box.left, box.top, box.width, box.height), Paint()..color = Colors.blue.withOpacity(.5));
      }
    }

    // bbox debug
    // final p1 = Paint()
    //   ..color = Colors.red.withOpacity(.5)
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 2 * scaleFactor;
    // canvas.drawRect(Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height), p1);
    // canvas.drawLine(Offset(bounds.left, bounds.top), Offset(bounds.right, bounds.bottom), p1);
    // canvas.drawLine(Offset(bounds.right, bounds.top), Offset(bounds.left, bounds.bottom), p1);
    // end

    canvas.restore();

    final text = TextPainter(
      text: TextSpan(
        text: "$zoomLevel\n$scale\n${dx.toStringAsFixed(2)}, ${dy.toStringAsFixed(2)}",
        style: const TextStyle(color: Colors.grey),
      ),
      textDirection: TextDirection.ltr,
    );
    text.layout();
    text.paint(canvas, Offset(size.width / 2 - text.width / 2, size.height - text.height - 50));
  }

  void paintTile(Canvas canvas, int zoom, int col, int row) async {
    final double top = (row * tileSize).toDouble();
    final double left = (col * tileSize).toDouble();
    canvas.drawRect(Rect.fromLTWH(left, top, tileSize, tileSize), Paint()..color = const Color(0xfffffffc));
    canvas.drawRect(Rect.fromLTWH(left, top, tileSize, tileSize), boundPaint..strokeWidth = scaleFactor);

    final tile = _resolveTile(zoom, col, row);

    for (final layer in tile.layers) {
      final pixelsPerTileUnit = 1 / layer.extent * tileSize;

      canvas.save();
      canvas.scale(pixelsPerTileUnit);
      canvas.translate((col * layer.extent).toDouble(), (row * layer.extent).toDouble());

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
        text: "Tile $zoom/$col/$row",
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
