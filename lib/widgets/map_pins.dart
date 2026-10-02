import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPins {
  MapPins._();
  static final _cache = <String, BitmapDescriptor>{};

  static Future<BitmapDescriptor> of(
    Color color, {
    required bool selected,
  }) async {
    final key = '${color.toARGB32()}-$selected';
    final hit = _cache[key];
    if (hit != null) return hit;
    final pin = await _draw(color, selected: selected);
    _cache[key] = pin;
    return pin;
  }

  static Future<void> warm(Iterable<Color> colors) async {
    for (final color in colors) {
      await of(color, selected: false);
      await of(color, selected: true);
    }
  }

  static Future<BitmapDescriptor> _draw(
    Color color, {
    required bool selected,
  }) async {
    const pixelRatio = 3.0;
    final logical = selected ? 28.0 : 20.0;
    final size = (logical * pixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - (selected ? 5 : 4) * pixelRatio / 3;

    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = color.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(center, radius, Paint()..color = color);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected ? 3.2 : 2.4) * pixelRatio / 3,
    );
    canvas.drawCircle(
      center,
      radius * 0.28,
      Paint()..color = Colors.white,
    );

    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
      width: logical,
      height: logical,
    );
  }
}
