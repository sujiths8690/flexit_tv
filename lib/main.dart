import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/error_reporter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(ErrorReporter.report(
      details.exception,
      details.stack,
      severity: 'critical',
    ));
  };
  // Allow all orientations — orientation is set dynamically from server
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    unawaited(ErrorReporter.report(
      error,
      stackTrace,
      severity: 'critical',
    ));
    return false;
  };
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FlexitApp());
}

class FlexitApp extends StatelessWidget {
  const FlexitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flexit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
