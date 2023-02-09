import 'dart:math';
import 'dart:ui';

import 'package:collection/collection.dart';

typedef TilePoint = Point<double>;
typedef Bounds = Rectangle<double>;

class TileLine {
  final List<TilePoint> points;
  Bounds? _bounds;

  TileLine(this.points);

  Path get path => Path()..addPolygon(_line(), false);
  Offset _point(TilePoint point) => Offset(point.x, point.y);
  List<Offset> _line() => points.map((e) => _point(e)).toList(growable: false);

  Bounds bounds() {
    var bounds = _bounds;
    if (bounds == null) {
      var minX = double.infinity;
      var maxX = double.negativeInfinity;
      var minY = double.infinity;
      var maxY = double.negativeInfinity;
      for (final point in points) {
        minX = min(minX, point.x);
        maxX = max(maxX, point.x);
        minY = min(minY, point.y);
        maxY = max(maxY, point.y);
      }
      bounds = Bounds.fromPoints(TilePoint(minX, minY), TilePoint(maxX, maxY));
      _bounds = bounds;
    }
    return bounds;
  }

  @override
  bool operator ==(Object other) => other is TileLine && _equality.equals(points, other.points);

  @override
  int get hashCode => _equality.hash(points);

  @override
  String toString() => "TileLine($points)";
}

class TilePolygon {
  final List<TileLine> rings;

  TilePolygon(this.rings);

  Offset _point(TilePoint point) => Offset(point.x, point.y);
  List<Offset> _line(List<TilePoint> points) => points.map((e) => _point(e)).toList(growable: false);

  Path get path {
    final path = Path()..fillType = PathFillType.evenOdd;
    for (final ring in rings) {
      path.addPolygon(_line(ring.points), true);
    }
    return path;
  }

  Bounds bounds() => rings.first.bounds();

  @override
  bool operator ==(Object other) => other is TilePolygon && _equality.equals(rings, other.rings);

  @override
  int get hashCode => _equality.hash(rings);

  @override
  String toString() => "TilePolygon($rings)";
}

const _equality = ListEquality();
