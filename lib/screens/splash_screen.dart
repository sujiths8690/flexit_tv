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
    _deviceService.initialize().catchError((_) async {
      await _deviceService.useOfflineStartupFallback();
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
  static const _flickerFrames = [
    [true, false, false, true, false, false],
    [false, true, false, false, false, true],
    [true, false, true, false, true, false],
    [false, false, true, true, false, false],
    [true, true, false, false, true, false],
    [false, true, true, false, false, true],
    [true, false, false, true, true, false],
    [false, true, false, true, false, true],
    [true, false, true, true, false, false],
    [false, true, true, false, true, true],
  ];

  const _LightFlexitIntro({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final showAll = t >= 0.76;
        final frameIndex = (t * 22).floor() % _flickerFrames.length;
        final visibleFrame = _flickerFrames[frameIndex];

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final shortest = size.shortestSide;
            final fontSize = (shortest * 0.065).clamp(26.0, 42.0);

            return ColoredBox(
              color: Colors.black,
              child: Center(
                child: RepaintBoundary(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _letters.length; i++)
                        _IntroLetter(
                          letter: _letters[i],
                          fontSize: fontSize,
                          visible: showAll || visibleFrame[i],
                        ),
                    ],
                  ),
                ),
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
  final double fontSize;
  final bool visible;

  const _IntroLetter({
    required this.letter,
    required this.fontSize,
    required this.visible,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fontSize * 0.62,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
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
