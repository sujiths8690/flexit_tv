// lib/screens/root_screen.dart
//
// Listens to DeviceService and routes to:
//   • QrPairingScreen   — device not paired
//   • MediaScreen        — paired, mode == media
//   • MenuBoardScreen    — paired, mode == menuBoard

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const _scheduleChannel = MethodChannel('com.flexit.display/schedule');
  Timer? _scheduleTimer;
  String? _lastNativeScheduleKey;
  String? _lastBackgroundKey;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_onServiceUpdate);
    _scheduleTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onServiceUpdate() {
    final orientation = widget.service.config?.orientation;
    if (orientation != null) {
      OrientationHelper.applySystemOrientation(orientation);
    }
    _syncNativeSchedule();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
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

    _syncNativeSchedule();

    // ── Media mode ────────────────────────────────────────────────────────
    if (!_isDisplayScheduleActive(display)) {
      _moveToBackgroundUntilNextStart(display);
      return const SizedBox.shrink();
    }

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
          initialRevealDelay: const Duration(milliseconds: 550),
        );
        return OrientationHelper.applyTransform(
          orientation: config.orientation,
          screenSize: screenSize,
          child: menu,
        );
      },
    );
  }

  void _syncNativeSchedule() {
    final display = widget.service.config?.displayConfig;
    if (display == null) return;

    final nextStart = _nextScheduleStart(display);
    final key = [
      display.scheduleEnabled,
      display.alwaysOn,
      display.scheduleStartTime,
      display.scheduleEndTime,
      nextStart?.millisecondsSinceEpoch,
    ].join('|');

    if (_lastNativeScheduleKey == key) return;
    _lastNativeScheduleKey = key;

    _scheduleChannel.invokeMethod('updateSchedule', {
      'baseUrl': widget.service.backendEndpoint,
      'deviceCode': widget.service.deviceCode,
      'scheduleEnabled': display.scheduleEnabled,
      'alwaysOn': display.alwaysOn,
      'startTime': display.scheduleStartTime,
      'endTime': display.scheduleEndTime,
      'nextStartAtMillis': nextStart?.millisecondsSinceEpoch,
    }).catchError((_) {});
  }

  void _moveToBackgroundUntilNextStart(DisplayConfig display) {
    final nextStart = _nextScheduleStart(display);
    final key = [
      display.scheduleStartTime,
      display.scheduleEndTime,
      nextStart?.millisecondsSinceEpoch,
    ].join('|');

    if (_lastBackgroundKey == key) return;
    _lastBackgroundKey = key;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleChannel.invokeMethod('backgroundUntilNextStart', {
        'nextStartAtMillis': nextStart?.millisecondsSinceEpoch,
      }).catchError((_) {});
    });
  }
}

bool _isDisplayScheduleActive(DisplayConfig display) {
  if (!display.scheduleEnabled) return true;
  if (display.alwaysOn) return true;

  int minutesOfDay(String value, int fallback) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return hour * 60 + minute;
  }

  final now = DateTime.now();
  final current = now.hour * 60 + now.minute;
  final start = minutesOfDay(display.scheduleStartTime, 9 * 60);
  final end = minutesOfDay(display.scheduleEndTime, 22 * 60);

  if (start == end) return true;
  if (start < end) return current >= start && current < end;
  return current >= start || current < end;
}

DateTime? _nextScheduleStart(DisplayConfig display) {
  if (!display.scheduleEnabled || display.alwaysOn) return null;

  int minutesOfDay(String value, int fallback) {
    final parts = value.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    return hour * 60 + minute;
  }

  final now = DateTime.now();
  final current = now.hour * 60 + now.minute;
  final start = minutesOfDay(display.scheduleStartTime, 9 * 60);
  final end = minutesOfDay(display.scheduleEndTime, 22 * 60);
  final startToday =
      DateTime(now.year, now.month, now.day).add(Duration(minutes: start));

  if (start == end) return null;
  if (start < end) {
    return current < start
        ? startToday
        : startToday.add(const Duration(days: 1));
  }

  return current < end ? startToday : startToday.add(const Duration(days: 1));
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
