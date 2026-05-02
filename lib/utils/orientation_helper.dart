// lib/utils/orientation_helper.dart
//
// Applies the orientation chosen in the mobile app by rotating the root widget.
// The server sends DeviceOrientation; we convert to a Flutter rotation transform.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import '../models/models.dart';

class OrientationHelper {
  /// Sets the system preferred orientation based on DisplayOrientation
  static Future<void> applySystemOrientation(DisplayOrientation orientation) async {
    switch (orientation) {
      case DisplayOrientation.landscape:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.landscapeLeft,
          services.DeviceOrientation.landscapeRight,
        ]);
        break;
      case DisplayOrientation.portrait:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.portraitUp,
        ]);
        break;
      case DisplayOrientation.rotatedLeft:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.landscapeLeft,
        ]);
        break;
      case DisplayOrientation.rotatedRight:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.landscapeRight,
        ]);
        break;
      case DisplayOrientation.inverted:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.portraitDown,
        ]);
        break;
    }
  }

  /// Returns a software transform for cases where the physical mount
  /// doesn't match system orientation (e.g. TV installed upside down)
  static Widget applyTransform({
    required DisplayOrientation orientation,
    required Widget child,
    required Size screenSize,
  }) {
    double angle = 0;
    switch (orientation) {
      case DisplayOrientation.rotatedLeft:
        angle = -1.5708; // -90°
        break;
      case DisplayOrientation.rotatedRight:
        angle = 1.5708; // +90°
        break;
      case DisplayOrientation.inverted:
        angle = 3.1416; // 180°
        break;
      default:
        angle = 0;
    }

    if (angle == 0) return child;

    return Transform.rotate(
      angle: angle,
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height,
        child: child,
      ),
    );
  }

  /// Responsive grid columns based on viewport width
  static int gridColumns(double width) {
    if (width >= 1600) return 4;
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Responsive font scale
  static double fontScale(double width) {
    if (width >= 1600) return 1.2;
    if (width >= 1000) return 1.0;
    if (width >= 600) return 0.85;
    return 0.7;
  }
}
