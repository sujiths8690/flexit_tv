// lib/screens/qr_pairing_screen.dart
//
// Shown when the display device is not yet paired. Displays:
//   • The device's unique QR code (encodes deviceCode)
//   • A friendly animated mascot at the bottom
//   • Rotating instruction prompts

import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/qr_code_widget.dart';

class QrPairingScreen extends StatefulWidget {
  final String deviceCode;
  final String realtimeStatus;
  final String configStatus;
  final String backendEndpoint;
  final String realtimeEndpoint;
  final Map<String, dynamic> deviceInfo;
  const QrPairingScreen({
    super.key,
    required this.deviceCode,
    required this.realtimeStatus,
    required this.configStatus,
    required this.backendEndpoint,
    required this.realtimeEndpoint,
    required this.deviceInfo,
  });

  @override
  State<QrPairingScreen> createState() => _QrPairingScreenState();
}

class _QrPairingScreenState extends State<QrPairingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _slideCtrl;
  late Animation<double> _pulseAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  int _tipIndex = 0;
  static const List<String> _tips = [
    'Open your flexit app',
    'Tap  +  and choose "Add Display"',
    'Scan the QR code or enter the device code',
    "That's it — your menu goes live!",
  ];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeIn);

    _slideCtrl.forward();
    _rotateTips();
  }

  void _rotateTips() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _slideCtrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
        _slideCtrl.forward();
        _rotateTips();
      });
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height > size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Background texture ─────────────────────────────────────────
          _BackgroundGrid(),

          // ── Ambient glow behind QR ─────────────────────────────────────
          Positioned(
            top: size.height * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.gold.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────────────
          SafeArea(
            child: isPortrait
                ? _buildPortraitLayout(size)
                : _buildLandscapeLayout(),
          ),

          // ── Mascot at bottom ───────────────────────────────────────────
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 560;
        final veryCompactHeight = constraints.maxHeight < 460;
        final horizontalPadding = compactHeight ? 36.0 : 60.0;
        final verticalPadding = compactHeight ? 24.0 : 40.0;
        final titleSize =
            veryCompactHeight ? 30.0 : (compactHeight ? 34.0 : 42.0);
        final tipSize = compactHeight ? 17.0 : 20.0;
        final logoSize = compactHeight ? 46.0 : 56.0;
        final qrSize = min(
          constraints.maxHeight * (compactHeight ? 0.50 : 0.55),
          compactHeight ? 280.0 : 320.0,
        );

        return Row(
          children: [
            // Left: branding & instructions
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  verticalPadding,
                  compactHeight ? 28 : 40,
                  verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo mark
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(compactHeight ? 12 : 14),
                        gradient: const LinearGradient(
                          colors: [AppTheme.gold, AppTheme.goldDim],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontFamily:
                                GoogleFonts.playfairDisplay().fontFamily,
                            fontSize: compactHeight ? 25 : 30,
                            color: AppTheme.background,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 16 : 32),
                    Text(
                      'Connect this\ndisplay to your\nbusiness',
                      style: TextStyle(
                        fontFamily: GoogleFonts.playfairDisplay().fontFamily,
                        fontSize: titleSize,
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                    SizedBox(height: compactHeight ? 14 : 24),
                    // Animated tip
                    SlideTransition(
                      position: _slideAnim,
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _tips[_tipIndex],
                                style: TextStyle(
                                  fontFamily: GoogleFonts.nunito().fontFamily,
                                  fontSize: tipSize,
                                  color: AppTheme.whiteDim,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: compactHeight ? 22 : 40),
                    // Device code pill
                    _DeviceCodeBadge(code: widget.deviceCode),
                    SizedBox(height: compactHeight ? 8 : 12),
                    _RealtimeStatusBadge(status: widget.realtimeStatus),
                    SizedBox(height: compactHeight ? 8 : 10),
                    Flexible(
                      child: _ConnectionDetails(
                        configStatus: widget.configStatus,
                        backendEndpoint: widget.backendEndpoint,
                        realtimeEndpoint: widget.realtimeEndpoint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right: QR code
            Padding(
              padding: EdgeInsets.fromLTRB(
                compactHeight ? 24 : 40,
                verticalPadding,
                compactHeight ? 48 : 80,
                verticalPadding,
              ),
              child: Center(
                child: ScaleTransition(
                  scale: _pulseAnim,
                  child: QrCodeWidget(
                    data: _qrData(),
                    size: qrSize,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPortraitLayout(Size size) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Text(
          'Connect this display',
          style: TextStyle(
            fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            fontSize: 34,
            color: AppTheme.white,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Scan with your flexit app',
          style: TextStyle(
            fontFamily: GoogleFonts.nunito().fontFamily,
            fontSize: 16,
            color: AppTheme.whiteDim,
          ),
        ),
        const SizedBox(height: 40),
        ScaleTransition(
          scale: _pulseAnim,
          child: QrCodeWidget(
            data: _qrData(),
            size: min(size.width * 0.55, 280),
          ),
        ),
        const SizedBox(height: 32),
        _DeviceCodeBadge(code: widget.deviceCode),
        const SizedBox(height: 12),
        _RealtimeStatusBadge(status: widget.realtimeStatus),
        const SizedBox(height: 10),
        _ConnectionDetails(
          configStatus: widget.configStatus,
          backendEndpoint: widget.backendEndpoint,
          realtimeEndpoint: widget.realtimeEndpoint,
        ),
        const SizedBox(height: 24),
        SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Text(
              _tips[_tipIndex],
              style: TextStyle(
                fontFamily: GoogleFonts.nunito().fontFamily,
                fontSize: 18,
                color: AppTheme.whiteDim,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  String _qrData() {
    // QR payload — your mobile app will read this
    return jsonEncode({
      'deviceCode': widget.deviceCode,
      'app': 'flexit',
      'version': 1,
      'deviceInfo': {
        ...widget.deviceInfo,
        'screenWidth': MediaQuery.of(context).size.width.round(),
        'screenHeight': MediaQuery.of(context).size.height.round(),
        'screenPixelRatio': MediaQuery.of(context).devicePixelRatio,
      },
    });
  }
}

class _ConnectionDetails extends StatelessWidget {
  final String configStatus;
  final String backendEndpoint;
  final String realtimeEndpoint;
  const _ConnectionDetails({
    required this.configStatus,
    required this.backendEndpoint,
    required this.realtimeEndpoint,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$configStatus\nHTTP $backendEndpoint\nWS $realtimeEndpoint',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: GoogleFonts.nunito().fontFamily,
        color: AppTheme.whiteDim,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

class _RealtimeStatusBadge extends StatelessWidget {
  final String status;
  const _RealtimeStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final connected = status.startsWith('connected');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: connected
            ? const Color(0xFF2ECC71).withOpacity(0.12)
            : AppTheme.gold.withOpacity(0.08),
        border: Border.all(
          color: connected ? const Color(0xFF2ECC71) : AppTheme.goldDim,
        ),
      ),
      child: Text(
        'Realtime: $status',
        style: TextStyle(
          fontFamily: GoogleFonts.nunito().fontFamily,
          color: connected ? const Color(0xFF7DFFA8) : AppTheme.whiteDim,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DeviceCodeBadge extends StatelessWidget {
  final String code;
  const _DeviceCodeBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldDim, width: 1),
        color: AppTheme.gold.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tv_rounded, color: AppTheme.gold, size: 18),
          const SizedBox(width: 10),
          Text(
            'Device Code: ',
            style: TextStyle(
              fontFamily: GoogleFonts.nunito().fontFamily,
              fontSize: 13,
              color: AppTheme.whiteDim,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            code,
            style: TextStyle(
              fontFamily: GoogleFonts.nunito().fontFamily,
              fontSize: 14,
              color: AppTheme.gold,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1C1C28).withOpacity(0.6)
      ..strokeWidth = 0.5;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
