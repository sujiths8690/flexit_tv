// lib/screens/root_screen.dart
//
// Listens to DeviceService and routes to:
//   • QrPairingScreen   — device not paired
//   • MediaScreen        — paired, mode == media
//   • MenuBoardScreen    — paired, mode == menuBoard

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/device_service.dart';
import '../models/models.dart';
import '../utils/orientation_helper.dart';
import 'qr_pairing_screen.dart';
import 'menu_board_screen.dart';
import 'media_screen.dart';

class RootScreen extends StatefulWidget {
  final DeviceService service;
  const RootScreen({super.key, required this.service});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    final orientation = widget.service.config?.orientation;
    if (orientation != null) {
      OrientationHelper.applySystemOrientation(orientation);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;

    if (service.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE8B84B)),
        ),
      );
    }

    final config = service.config;

    // ── Not paired → show QR ─────────────────────────────────────────────
    if (config == null || !config.isPaired) {
      return QrPairingScreen(
        deviceCode: service.deviceCode,
        realtimeStatus: service.realtimeStatus,
        configStatus: service.configStatus,
        backendEndpoint: service.backendEndpoint,
        realtimeEndpoint: service.realtimeEndpoint,
      );
    }

    final display = config.displayConfig;

    // ── No display config yet ────────────────────────────────────────────
    if (display == null) {
      return _WaitingScreen(businessName: config.businessName);
    }

    // ── Media mode ────────────────────────────────────────────────────────
    if (display.mode == DisplayMode.media) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          final media = MediaScreen(
            mediaUrl: display.mediaUrl ?? '',
            mediaType: display.mediaType ?? 'image',
            mediaItems: display.mediaItems,
            slideDurationSeconds: display.autoScrollIntervalSeconds ?? 8,
            transitionStyle: display.transitionStyle,
            transitionSpeedSeconds: display.transitionSpeedSeconds,
            businessName: config.businessName,
            businessLogoUrl: config.businessLogoUrl,
            showLogo: display.showLogo,
            showCompanyName: display.showCompanyName,
          );
          return OrientationHelper.applyTransform(
            orientation: config.orientation,
            screenSize: screenSize,
            child: media,
          );
        },
      );
    }

    // ── Menu board mode ───────────────────────────────────────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final menuSize = OrientationHelper.contentSizeFor(
          orientation: config.orientation,
          screenSize: screenSize,
        );
        final menu = MenuBoardScreen(
          config: config,
          displayConfig: display,
          screenSize: menuSize,
        );
        return OrientationHelper.applyTransform(
          orientation: config.orientation,
          screenSize: screenSize,
          child: menu,
        );
      },
    );
  }
}

class _WaitingScreen extends StatelessWidget {
  final String? businessName;
  const _WaitingScreen({this.businessName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFE8B84B)),
            const SizedBox(height: 24),
            Text(
              businessName != null ? 'Welcome, $businessName!' : 'Connected',
              style: TextStyle(
                fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                fontSize: 28,
                color: Color(0xFFF5F5F0),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Waiting for display configuration from your mobile app…',
              style: TextStyle(
                fontFamily: GoogleFonts.nunito().fontFamily,
                color: Color(0xFFB0AFA8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
