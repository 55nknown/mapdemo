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
          _position.pan += details.focalPointDelta / _position.zoom;
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
