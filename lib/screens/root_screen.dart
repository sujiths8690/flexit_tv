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
import '../services/local_media_service.dart';
import '../utils/orientation_helper.dart';
import 'qr_pairing_screen.dart';
import 'menu_board_screen.dart';
import 'media_screen.dart';

List<String> _contentModesFrom(String value) {
  final modes = value
      .split(',')
      .map((mode) => mode.trim())
      .where((mode) => mode.isNotEmpty)
      .toList();
  if (modes.isEmpty || modes.contains('allCategories')) {
    return const [
      'category',
      'allMedia',
      'comboOffers',
      'offers',
      'notices',
      'todaysStar'
    ];
  }
  return modes;
}

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
    final contentModes = _contentModesFrom(display.contentMode);
    final hasMediaSection =
        contentModes.contains('allMedia') || contentModes.contains('media');
    final hasMenuSection = contentModes.any(
      (mode) =>
          mode == 'allCategories' ||
          mode == 'category' ||
          mode == 'comboOffers' ||
          mode == 'offers' ||
          mode == 'notices' ||
          mode == 'todaysStar',
    );

    if (hasMediaSection && hasMenuSection) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          final contentSize = OrientationHelper.contentSizeFor(
            orientation: config.orientation,
            screenSize: screenSize,
          );
          final mixed = _MixedDisplayScreen(
            config: config,
            display: display,
            screenSize: contentSize,
          );
          return OrientationHelper.applyTransform(
            orientation: config.orientation,
            screenSize: screenSize,
            child: mixed,
          );
        },
      );
    }

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

class _MixedDisplayScreen extends StatefulWidget {
  final DeviceConfig config;
  final DisplayConfig display;
  final Size screenSize;

  const _MixedDisplayScreen({
    required this.config,
    required this.display,
    required this.screenSize,
  });

  @override
  State<_MixedDisplayScreen> createState() => _MixedDisplayScreenState();
}

class _MixedDisplayScreenState extends State<_MixedDisplayScreen> {
  Timer? _timer;
  int _index = 0;
  List<DisplayMediaItem> _localMediaItems = const [];
  bool _isScanningLocalMedia = false;

  List<String> get _contentModes =>
      _contentModesFrom(widget.display.contentMode);

  bool get _usesBackendMedia => _contentModes.contains('media');

  List<DisplayMediaItem> get _availableMediaItems =>
      _usesBackendMedia && widget.display.mediaItems.isNotEmpty
          ? widget.display.mediaItems
          : _localMediaItems;

  bool get _hasMediaContent => _availableMediaItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scanLocalMediaIfNeeded();
    _startTimer();
  }

  @override
  void didUpdateWidget(_MixedDisplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.display.contentMode != widget.display.contentMode ||
        oldWidget.display.autoScrollIntervalSeconds !=
            widget.display.autoScrollIntervalSeconds ||
        oldWidget.display.mediaItems.length !=
            widget.display.mediaItems.length) {
      _index = 0;
      _scanLocalMediaIfNeeded();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_hasMediaContent || _index == 0) return;
    final seconds = widget.display.autoScrollIntervalSeconds ?? 8;
    _timer = Timer.periodic(Duration(seconds: seconds < 6 ? 6 : seconds), (_) {
      if (!mounted) return;
      setState(() => _index = 0);
      _timer?.cancel();
    });
  }

  void _showMediaAfterMenuCycle() {
    if (!_hasMediaContent || _index == 1) return;
    setState(() => _index = 1);
    _startTimer();
  }

  Future<void> _scanLocalMediaIfNeeded() async {
    if (_usesBackendMedia && widget.display.mediaItems.isNotEmpty) return;
    if (_isScanningLocalMedia) return;
    _isScanningLocalMedia = true;
    try {
      final items = await LocalMediaService.scan();
      if (!mounted) return;
      setState(() {
        _localMediaItems = items;
        if (items.isEmpty) _index = 0;
      });
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _localMediaItems = const [];
        _index = 0;
      });
    } finally {
      _isScanningLocalMedia = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = MenuBoardScreen(
      config: widget.config,
      displayConfig: widget.display,
      screenSize: widget.screenSize,
      initialRevealDelay: const Duration(milliseconds: 550),
      onCycleComplete: _showMediaAfterMenuCycle,
    );

    if (!_hasMediaContent) {
      return menu;
    }

    final media = MediaScreen(
      mediaUrl: widget.display.mediaUrl ?? '',
      mediaType: widget.display.mediaType ?? 'image',
      mediaItems: _availableMediaItems,
      slideDurationSeconds: widget.display.autoScrollIntervalSeconds ?? 8,
      transitionStyle: widget.display.transitionStyle,
      transitionSpeedSeconds: widget.display.transitionSpeedSeconds,
      businessName: widget.config.businessName,
      businessLogoUrl: widget.config.businessLogoUrl,
      showLogo: widget.display.showLogo,
      showCompanyName: widget.display.showCompanyName,
    );

    return IndexedStack(
      index: _index,
      children: [
        menu,
        media,
      ],
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
