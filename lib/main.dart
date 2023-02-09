import 'package:flutter/material.dart';
import 'package:mapdemo/ui/map/map_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'OC Map Demo',
      home: MapView(),
    );
  }
}
