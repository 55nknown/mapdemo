import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:mapdemo/data/models/vector_tile.pb.dart';

class MapClient {
  Future<Tile> getTile(int zoomLevel, int tileCol, int tileRow) async {
    final url = "http://localhost:8080/${zoomLevel}_${tileCol}_${pow(2, zoomLevel) - 1 - tileRow}.tile.pbf";
    print(url);
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return Tile.fromBuffer(res.bodyBytes);
    return Tile(layers: null);
  }
}
