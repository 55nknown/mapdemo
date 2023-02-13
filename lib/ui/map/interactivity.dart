import 'dart:math';

import 'package:flutter/material.dart';

class Position {
  double zoom;
  double angle;
  Offset pan;

  Position({
    this.zoom = 1.0,
    this.angle = 0.0,
    this.pan = Offset.zero,
  });
}

typedef InteractiveBuilder = Widget Function(BuildContext context, Position position);

class Interactivity extends StatefulWidget {
  const Interactivity({super.key, required this.builder});

  final InteractiveBuilder builder;

  @override
  State<Interactivity> createState() => _InteractivityState();
}

class _InteractivityState extends State<Interactivity> {
  double _activeAngle = 0.0;
  double _activeZoom = 1.0;

  final _position = Position();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        setState(() {
          _position.angle = _activeAngle;
          _position.zoom = _activeZoom;
        });
      },
      onScaleUpdate: (details) {
        setState(() {
          _position.angle = _activeAngle + details.rotation;
          _position.zoom = _activeZoom * details.scale;
          if (_position.zoom < 1.0) _position.zoom = 1.0;
          if (_position.zoom > 14.0) _position.zoom = 14.0;
          final delta = details.focalPointDelta;
          final offsetX = delta.dx * cos(_position.angle) + delta.dy * sin(_position.angle);
          final offsetY = -delta.dx * sin(_position.angle) + delta.dy * cos(_position.angle);
          _position.pan += Offset(offsetX, offsetY) / (pow(2, _position.zoom) / 2.0);
        });
      },
      onScaleEnd: (details) {
        setState(() {
          _activeAngle = _position.angle;
          _activeZoom = _position.zoom;
        });
      },
      child: widget.builder(
        context,
        _position,
      ),
    );
  }
}
