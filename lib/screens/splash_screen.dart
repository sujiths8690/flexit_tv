// lib/screens/splash_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/device_service.dart';
import '../theme/app_theme.dart';
import 'root_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  final DeviceService _deviceService = DeviceService();
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _logoScale = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );
    _logoOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _ctrl.forward();
    _boot();
  }

  void _boot() {
    _deviceService.initialize().catchError((_) {
      _deviceService.useOfflineStartupFallback();
    });

    _navigationTimer = Timer(const Duration(milliseconds: 1400), _showRoot);
  }

  void _showRoot() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => RootScreen(service: _deviceService),
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Ambient glow
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.gold.withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoOpacity,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppTheme.gold, AppTheme.goldDim],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withOpacity(0.35),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontFamily:
                                GoogleFonts.playfairDisplay().fontFamily,
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _logoOpacity,
                  child: Text(
                    'MENUBOARD',
                    style: TextStyle(
                      fontFamily: GoogleFonts.nunito().fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                      color: AppTheme.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                FadeTransition(
                  opacity: _taglineOpacity,
                  child: Text(
                    'Premium Digital Menu Experience',
                    style: TextStyle(
                      fontFamily: GoogleFonts.nunito().fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      color: AppTheme.gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom loading bar
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineOpacity,
              child: Column(
                children: [
                  const SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                      backgroundColor: Color(0xFF2A2A38),
                      valueColor: AlwaysStoppedAnimation(AppTheme.gold),
                      minHeight: 2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Connecting to your business...',
                    style: TextStyle(
                      fontFamily: GoogleFonts.nunito().fontFamily,
                      fontSize: 12,
                      color: AppTheme.whiteDim,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
