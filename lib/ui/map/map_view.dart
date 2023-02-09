import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mapdemo/api/client.dart';
import 'package:mapdemo/data/models/vector_tile.pb.dart';
import 'package:mapdemo/ui/map/interactivity.dart';
import 'package:mapdemo/ui/map/map_painter.dart';

class MapTile {
  final int zoom;
  final int col;
  final int row;
  final Tile data;

  MapTile(this.zoom, this.col, this.row, this.data);

  String get key => "$zoom/$col/$row";
}

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final client = MapClient();

  final Map<String, Tile> _tileMap = {};

  late final StreamController<MapTile> _stream;

  @override
  void initState() {
    super.initState();

    _stream = StreamController.broadcast();
  }

  @override
  void dispose() {
    _stream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MapTile>(
      stream: _stream.stream.map((event) {
        if (!_tileMap.containsKey(event.key)) {
          _tileMap[event.key] = event.data;
        }
        return event;
      }),
      builder: (context, snapshot) {
        return Interactivity(
          builder: (context, position) => CustomPaint(
            painter: MapPainter(
              position: position,
              resolver: (zoom, col, row) {
                final tileKey = "$zoom/$col/$row";
                if (!_tileMap.containsKey(tileKey)) {
                  client.getTile(zoom, col, row).then(
                        (value) => _stream.add(
                          MapTile(zoom, col, row, value),
                        ),
                      );
                  return Tile(layers: null);
                } else {
                  return _tileMap[tileKey]!;
                }
              },
            ),
          ),
        );
      },
    );
  }
}
