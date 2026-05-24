import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';

class NoticeShowcase extends StatelessWidget {
  final List<NoticeItem> notices;
  final int pageIndex;
  final Size screenSize;
  final double transitionSpeedSeconds;

  const NoticeShowcase({
    super.key,
    required this.notices,
    required this.pageIndex,
    required this.screenSize,
    required this.transitionSpeedSeconds,
  });

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) return const SizedBox.shrink();
    final safeIndex = pageIndex % notices.length;
    final notice = notices[safeIndex];
    final durationMs =
        (transitionSpeedSeconds * 1000).round().clamp(220, 1200).toInt();

    return ClipRect(
      child: _NoticePoster(
        notice: notice,
        screenSize: screenSize,
        transitionDuration: Duration(milliseconds: durationMs),
      ),
    );
  }
}

class _NoticePoster extends StatelessWidget {
  final NoticeItem notice;
  final Size screenSize;
  final Duration transitionDuration;

  const _NoticePoster({
    required this.notice,
    required this.screenSize,
    required this.transitionDuration,
  });

  @override
  Widget build(BuildContext context) {
    final width = screenSize.width;
    final height = screenSize.height;
    final isPortrait = height >= width;
    final shortest = min(width, height);
    final megaphoneWidth = _clampDouble(
      isPortrait ? width * 0.70 : width * 0.34,
      210,
      620,
    );
    final megaphoneHeight = megaphoneWidth * 0.72;
    final bannerWidth = width * (isPortrait ? 0.92 : 0.82);
    final bannerHeight = _clampDouble(height * 0.22, 118, 260);
    final bannerTop = height * (isPortrait ? 0.42 : 0.38);
    final contentTop = bannerTop + bannerHeight + height * 0.07;
    final contentBottom = height * 0.06;
    final contentHeight = max(90.0, height - contentTop - contentBottom);

    return ColoredBox(
      color: const Color(0xFF42A7D0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3E9FC7), Color(0xFF53B5DD)],
              ),
            ),
          ),
          Positioned(
            top: height * 0.035,
            left: isPortrait ? width * 0.10 : width * 0.30,
            width: megaphoneWidth,
            height: megaphoneHeight,
            child: Image.asset(
              'assets/loudspeaker/loudspeaker-icon.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: bannerTop,
            left: (width - bannerWidth) / 2,
            width: bannerWidth,
            height: bannerHeight,
            child: const _AnnouncementBanner(),
          ),
          Positioned(
            top: contentTop,
            left: width * (isPortrait ? 0.10 : 0.14),
            right: width * (isPortrait ? 0.10 : 0.14),
            height: contentHeight,
            child: _NoticeBodyText(
              noticeId: notice.id,
              content: notice.content,
              fontSize: _clampDouble(shortest * 0.052, 26, 54),
              transitionDuration: transitionDuration,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBanner extends StatelessWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.055,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _BannerPainter()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'IMPORTANT',
                      style: GoogleFonts.bebasNeue(
                        color: const Color(0xFF3B91B7),
                        fontSize: 128,
                        fontWeight: FontWeight.w700,
                        height: 0.86,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'ANNOUNCEMENT',
                      style: GoogleFonts.bebasNeue(
                        color: const Color(0xFF3B91B7),
                        fontSize: 78,
                        fontWeight: FontWeight.w700,
                        height: 0.9,
                        letterSpacing: 0,
                      ),
                    ),
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

class _NoticeBodyText extends StatelessWidget {
  final int noticeId;
  final String content;
  final double fontSize;
  final Duration transitionDuration;

  const _NoticeBodyText({
    required this.noticeId,
    required this.content,
    required this.fontSize,
    required this.transitionDuration,
  });

  @override
  Widget build(BuildContext context) {
    final text = content.trim();
    final style = _containsMalayalam(text)
        ? GoogleFonts.notoSansMalayalam(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: 0,
          )
        : GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: 0,
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: AnimatedSwitcher(
              duration: transitionDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.16),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: FittedBox(
                key: ValueKey('notice-text-$noticeId-$text'),
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Text(
                    _containsMalayalam(text) ? text : text.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final main = Path()
      ..moveTo(size.width * 0.02, size.height * 0.08)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.96, size.height * 0.58)
      ..lineTo(0, size.height * 0.72)
      ..close();
    final bottom = Path()
      ..moveTo(size.width * 0.08, size.height * 0.58)
      ..lineTo(size.width * 0.92, size.height * 0.47)
      ..lineTo(size.width * 0.88, size.height)
      ..lineTo(size.width * 0.06, size.height)
      ..close();
    canvas.drawPath(main, paint);
    canvas.drawPath(bottom, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

bool _containsMalayalam(String text) {
  for (final codeUnit in text.runes) {
    if (codeUnit >= 0x0D00 && codeUnit <= 0x0D7F) return true;
  }
  return false;
}

double _clampDouble(double value, double min, double max) =>
    value.clamp(min, max).toDouble();
