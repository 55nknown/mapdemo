// ignore_for_file: unused_element

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapdemo/data/models/vector_tile.pb.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

class MapClient {
  final _lock = Completer<bool>();
  late final Database _db;

  MapClient() {
    init();
  }

  Future<void> init() async {
    final buf = await rootBundle.load("assets/hungary-latest.mbtiles");
    final path = await getDatabasesPath();
    final dbPath = join(path, "tiles.db");
    await File(dbPath).writeAsBytes(buf.buffer.asUint8List());
    _db = await openDatabase(dbPath);
    _lock.complete(true);
  }

  Future<Tile> getTile(int zoomLevel, int tileCol, int tileRow) async {
    await _lock.future;
    tileRow = pow(2, zoomLevel).toInt() - 1 - tileRow;
    return await _localTile(zoomLevel, tileCol, tileRow) ?? Tile(layers: null);
  }

  Future<Tile?> _localTile(int zoomLevel, int tileCol, int tileRow) async {
    final tiles = await _db.rawQuery("SELECT tile_data FROM tiles WHERE zoom_level = $zoomLevel AND tile_column = $tileCol AND tile_row = $tileRow");
    if (tiles.isEmpty || tiles[0]["tile_data"] == null) return null;
    return Tile.fromBuffer((tiles[0]["tile_data"]! as List).cast<int>());
  }

  Future<Tile?> _networkTile(int zoomLevel, int tileCol, int tileRow) async {
    final url = "http://localhost:8080/${zoomLevel}_${tileCol}_$tileRow.tile.pbf";
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return Tile.fromBuffer(res.bodyBytes);
    return null;
  }
}
