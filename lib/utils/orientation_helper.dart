// lib/utils/orientation_helper.dart
//
// Applies the orientation chosen in the mobile app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import '../models/models.dart';

class OrientationHelper {
  /// Sets the system preferred orientation based on DisplayOrientation.
  static Future<void> applySystemOrientation(
    DisplayOrientation orientation,
  ) async {
    switch (orientation) {
      case DisplayOrientation.normal:
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
      case DisplayOrientation.left:
      case DisplayOrientation.rotatedLeft:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.landscapeLeft,
        ]);
        break;
      case DisplayOrientation.right:
      case DisplayOrientation.rotatedRight:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.landscapeRight,
        ]);
        break;
      case DisplayOrientation.inverted:
        await services.SystemChrome.setPreferredOrientations([
          services.DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }

  /// Returns a software transform for TVs mounted in a non-standard direction.
  static Widget applyTransform({
    required DisplayOrientation orientation,
    required Widget child,
    required Size screenSize,
  }) {
    final quarterTurns = switch (orientation) {
      DisplayOrientation.left || DisplayOrientation.rotatedLeft => 3,
      DisplayOrientation.right || DisplayOrientation.rotatedRight => 1,
      DisplayOrientation.inverted => 2,
      _ => 0,
    };

    if (quarterTurns == 0) return child;

    return SizedBox.expand(
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: child,
      ),
    );
  }

  static Size contentSizeFor({
    required DisplayOrientation orientation,
    required Size screenSize,
  }) {
    return switch (orientation) {
      DisplayOrientation.left ||
      DisplayOrientation.right ||
      DisplayOrientation.rotatedLeft ||
      DisplayOrientation.rotatedRight =>
        Size(screenSize.height, screenSize.width),
      _ => screenSize,
    };
  }

  /// Responsive grid columns based on viewport width.
  static int gridColumns(double width) {
    if (width >= 1600) return 4;
    if (width >= 1000) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  /// Responsive font scale.
  static double fontScale(double width) {
    if (width >= 1600) return 1.2;
    if (width >= 1000) return 1.0;
    if (width >= 600) return 0.85;
    return 0.7;
  }
}
