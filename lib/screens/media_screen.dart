// lib/screens/media_screen.dart
//
// Shown when displayConfig.mode == DisplayMode.media.
// Supports image or video (video_player package).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/mascot_widget.dart';

class MediaScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType; // 'image' | 'video'

  const MediaScreen({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
  });

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Media content ─────────────────────────────────────────
            if (widget.mediaType == 'image')
              Image.network(
                widget.mediaUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const _MediaError(),
              )
            else
              // Video support — uncomment after adding video_player to pubspec.yaml
              // VideoPlayerWidget(url: widget.mediaUrl),
              _VideoPlaceholder(url: widget.mediaUrl),

            // ── Subtle bottom mascot ──────────────────────────────────
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MascotWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String url;
  const _VideoPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_outline, color: AppTheme.gold, size: 80),
            const SizedBox(height: 16),

            Text(
              'Video Display',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                color: AppTheme.white,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Add video_player package to enable video playback',
              style: GoogleFonts.nunito(
                color: AppTheme.whiteDim,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: AppTheme.whiteDim,
              size: 60,
            ),
            const SizedBox(height: 16),

            Text(
              'Media unavailable',
              style: GoogleFonts.nunito(
                color: AppTheme.whiteDim,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
