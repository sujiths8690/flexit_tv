// ignore_for_file: unused_element

// lib/screens/root_screen.dart
//
// Listens to DeviceService and routes to:
//   • QrPairingScreen   — device not paired
//   • MediaScreen        — paired, mode == media
//   • MenuBoardScreen    — paired, mode == menuBoard

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
        deviceInfo: service.deviceInfo,
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
      final usesBackendMedia =
          _contentModesFrom(display.contentMode).contains('media');
      return _SubscriptionGate(
        expired: service.isSubscriptionExpired,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize =
                Size(constraints.maxWidth, constraints.maxHeight);
            final media = MediaScreen(
              mediaUrl: display.mediaUrl ?? '',
              mediaType: display.mediaType ?? 'image',
              mediaItems: usesBackendMedia ? display.mediaItems : const [],
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
        ),
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
      return _SubscriptionGate(
        expired: service.isSubscriptionExpired,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenSize =
                Size(constraints.maxWidth, constraints.maxHeight);
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
        ),
      );
    }

    return _SubscriptionGate(
      expired: service.isSubscriptionExpired,
      child: LayoutBuilder(
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
      ),
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
  int _index = 0;
  List<DisplayMediaItem> _localMediaItems = const [];
  bool _isScanningLocalMedia = false;

  List<String> get _contentModes =>
      _contentModesFrom(widget.display.contentMode);

  bool get _usesBackendMedia =>
      _contentModes.contains('media') && !_contentModes.contains('allMedia');

  List<DisplayMediaItem> get _availableMediaItems =>
      _usesBackendMedia && widget.display.mediaItems.isNotEmpty
          ? widget.display.mediaItems
          : _localMediaItems;

  bool get _hasMediaContent => _availableMediaItems.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scanLocalMediaIfNeeded();
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
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showMediaAfterMenuCycle() {
    if (!_hasMediaContent || _index == 1) return;
    setState(() => _index = 1);
  }

  void _showMenuAfterMediaCycle() {
    if (!mounted || _index == 0) return;
    setState(() => _index = 0);
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
      isActive: _index == 0,
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
      isActive: _index == 1,
      onPlaylistCycleComplete: _showMenuAfterMediaCycle,
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

class _SubscriptionGate extends StatelessWidget {
  final bool expired;
  final Widget child;

  const _SubscriptionGate({required this.expired, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!expired) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: RepaintBoundary(child: child),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xCC000000),
            child: Center(
              child: _ExpiredOverlayCard(
                maxWidth: MediaQuery.sizeOf(context).width - 64,
                maxHeight: MediaQuery.sizeOf(context).height - 64,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpiredOverlayCard extends StatelessWidget {
  final double maxWidth;
  final double maxHeight;

  const _ExpiredOverlayCard({
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final scale = (maxWidth / 780).clamp(0.65, 1.0);

    return Transform.scale(
      scale: scale,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 780,
          maxHeight: maxHeight / scale,
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(decoration: TextDecoration.none),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF17171B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2E2E38), width: 0.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ExpiredHeader(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _RechargeStepsPanel()),
                      _PanelDivider(),
                      Expanded(child: _RechargeQrPanel()),
                    ],
                  ),
                  _ExpiredFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpiredHeader extends StatelessWidget {
  const _ExpiredHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12121A),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFF3A1A1A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE05050),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your subscription has expired',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFFF0EDE8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Flexit Display - action required to resume',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF888780),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RechargeStepsPanel extends StatelessWidget {
  const _RechargeStepsPanel();

  static const _steps = [
    _RechargeStep(
      label: 'Open settings',
      detail: 'In the Flexit mobile app, go to Settings',
    ),
    _RechargeStep(
      label: 'Tap upgrade',
      detail: 'Click Upgrade next to your current plan',
    ),
    _RechargeStep(
      label: 'Select a plan',
      detail: 'Choose the plan that works for your business',
    ),
    _RechargeStep(
      label: 'Complete payment',
      detail: 'Your display resumes automatically after payment',
      isDone: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW TO RECHARGE',
            style: GoogleFonts.nunito(
              color: const Color(0xFF888780),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_steps.length, (index) {
            final step = _steps[index];
            final isLast = index == _steps.length - 1;
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepBadge(
                      number: index + 1,
                      isDone: step.isDone,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.label,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFFF0EDE8),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step.detail,
                              style: GoogleFonts.nunito(
                                color: const Color(0xFF888780),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (!isLast)
                  Padding(
                    padding: const EdgeInsets.only(left: 14, top: 6, bottom: 6),
                    child: Container(
                      width: 0.5,
                      height: 18,
                      color: const Color(0xFF2E2E38),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _RechargeStep {
  final String label;
  final String detail;
  final bool isDone;

  const _RechargeStep({
    required this.label,
    required this.detail,
    this.isDone = false,
  });
}

class _StepBadge extends StatelessWidget {
  final int number;
  final bool isDone;

  const _StepBadge({required this.number, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF1A3A2A) : const Color(0xFF1A2A3A),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, size: 14, color: Color(0xFF4CAF82))
            : Text(
                '$number',
                style: GoogleFonts.nunito(
                  color: const Color(0xFF5B9BD5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _RechargeQrPanel extends StatelessWidget {
  static const _upgradeDeepLink = 'texboard://settings-upgrade';

  const _RechargeQrPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'QUICK RECHARGE',
            style: GoogleFonts.nunito(
              color: const Color(0xFF888780),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2E2E38), width: 0.5),
            ),
            child: QrImageView(
              data: _upgradeDeepLink,
              version: QrVersions.auto,
              size: 140,
              backgroundColor: Colors.white,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0A0A0F),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0A0A0F),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Scan to recharge',
            style: GoogleFonts.nunito(
              color: const Color(0xFFF0EDE8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Opens Flexit plan page',
            style: GoogleFonts.nunito(
              color: const Color(0xFF888780),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF12121A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2E2E38), width: 0.5),
            ),
            child: Text(
              _upgradeDeepLink,
              style: GoogleFonts.dmMono(
                color: const Color(0xFF888780),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 0.5, color: const Color(0xFF2E2E38));
  }
}

class _ExpiredFooter extends StatelessWidget {
  const _ExpiredFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF12121A),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: Center(
        child: Text.rich(
          TextSpan(
            text: 'Need help? Contact ',
            style: GoogleFonts.nunito(
              color: const Color(0xFF888780),
              fontSize: 12,
            ),
            children: const [
              TextSpan(
                text: 'flexitontv@gmail.com',
                style: TextStyle(color: Color(0xFF5B9BD5)),
              ),
            ],
          ),
        ),
      ),
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
                color: const Color(0xFFF5F5F0),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Waiting for display configuration from your mobile app…',
              style: TextStyle(
                fontFamily: GoogleFonts.nunito().fontFamily,
                color: const Color(0xFFB0AFA8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
