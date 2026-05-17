// lib/screens/splash_screen.dart
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../services/device_service.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _introDuration = Duration(milliseconds: 3800);
  static const _handoffSettleDelay = Duration(milliseconds: 300);

  late final AnimationController _ctrl;
  final DeviceService _deviceService = DeviceService();
  bool _hasShownRoot = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _introDuration);
    _boot();
  }

  void _boot() {
    _deviceService.initialize().catchError((_) {
      _deviceService.useOfflineStartupFallback();
    });

    _ctrl.forward().whenComplete(() async {
      await Future<void>.delayed(_handoffSettleDelay);
      _showRoot();
    });
  }

  void _showRoot() {
    if (!mounted || _hasShownRoot) return;
    _hasShownRoot = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RootScreen(service: _deviceService),
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: RepaintBoundary(
        child: _LightFlexitIntro(animation: _ctrl),
      ),
    );
  }
}

class _LightFlexitIntro extends StatelessWidget {
  final Animation<double> animation;
  static const _letters = ['f', 'l', 'e', 'x', 'i', 't'];

  const _LightFlexitIntro({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final join = Curves.easeInOutCubic.transform(
          ((t - 0.04) / 0.58).clamp(0.0, 1.0),
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final shortest = size.shortestSide;
            final fontSize = (shortest * 0.065).clamp(26.0, 42.0);
            final finalGap = (size.width * 0.03).clamp(20.0, 38.0);
            final totalWidth = finalGap * (_letters.length - 1);
            final firstFinalX = (size.width - totalWidth) / 2;
            final centerY = size.height / 2;
            final initialXs = <double>[
              size.width * 0.09,
              size.width * 0.25,
              size.width * 0.42,
              size.width * 0.58,
              size.width * 0.74,
              size.width * 0.91,
            ];

            return ColoredBox(
              color: Colors.black,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  for (var i = 0; i < _letters.length; i++)
                    _IntroLetter(
                      letter: _letters[i],
                      x: ui.lerpDouble(
                        initialXs[i],
                        firstFinalX + finalGap * i,
                        join,
                      )!,
                      y: centerY,
                      fontSize: fontSize,
                      opacity: Curves.easeOut.transform(
                        ((t - 0.02) / 0.22).clamp(0.0, 1.0),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _IntroLetter extends StatelessWidget {
  final String letter;
  final double x;
  final double y;
  final double fontSize;
  final double opacity;

  const _IntroLetter({
    required this.letter,
    required this.x,
    required this.y,
    required this.fontSize,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - fontSize * 0.25,
      top: y - fontSize * 0.58,
      child: Opacity(
        opacity: opacity,
        child: Text(
          letter,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
            height: 1,
            letterSpacing: 0,
            color: const Color(0xFFE7ECF2),
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.26),
                blurRadius: 8,
              ),
              const Shadow(
                color: Color(0xFF5E6874),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
