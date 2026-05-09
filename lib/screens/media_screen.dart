// lib/screens/media_screen.dart
//
// Shown when displayConfig.mode == DisplayMode.media.
// Supports image or video (video_player package).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/business_brand_mark.dart';
import '../widgets/mascot_widget.dart';

class MediaScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType; // 'image' | 'video'
  final List<DisplayMediaItem> mediaItems;
  final int slideDurationSeconds;
  final String transitionStyle;
  final double transitionSpeedSeconds;
  final String? businessName;
  final String? businessLogoUrl;
  final bool showLogo;
  final bool showCompanyName;

  const MediaScreen({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.mediaItems = const [],
    this.slideDurationSeconds = 8,
    this.transitionStyle = 'fade',
    this.transitionSpeedSeconds = 0.5,
    this.businessName,
    this.businessLogoUrl,
    this.showLogo = true,
    this.showCompanyName = true,
  });

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(MediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mediaItems != widget.mediaItems ||
        oldWidget.slideDurationSeconds != widget.slideDurationSeconds) {
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.mediaItems.length <= 1) return;
    _timer = Timer.periodic(
      Duration(seconds: widget.slideDurationSeconds),
      (_) {
        if (!mounted) return;
        setState(() => _index = (_index + 1) % widget.mediaItems.length);
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.mediaItems.isNotEmpty
        ? widget.mediaItems[_index % widget.mediaItems.length]
        : DisplayMediaItem(
            id: 0,
            fileName: '',
            url: widget.mediaUrl,
            type: widget.mediaType,
          );
    final url = _absoluteUrl(current.url);
    final type = current.type.toLowerCase();
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: Duration(
            milliseconds: (widget.transitionSpeedSeconds * 1000).round()),
        transitionBuilder: _transitionBuilder,
        child: Stack(
          key: ValueKey('${current.id}-${current.url}'),
          fit: StackFit.expand,
          children: [
            // ── Media content ─────────────────────────────────────────
            if (type == 'image')
              Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const _MediaError(),
              )
            else
              // Video support — uncomment after adding video_player to pubspec.yaml
              // VideoPlayerWidget(url: widget.mediaUrl),
              _VideoPlaceholder(url: url),

            // ── Subtle bottom mascot ──────────────────────────────────
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MascotWidget(),
            ),
            if (widget.showLogo || widget.showCompanyName)
              BusinessBrandMark(
                businessName:
                    widget.showCompanyName ? widget.businessName : null,
                logoUrl: widget.showLogo ? widget.businessLogoUrl : null,
                darkBackdrop: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _transitionBuilder(Widget child, Animation<double> animation) {
    switch (widget.transitionStyle.toLowerCase()) {
      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.08, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'zoom':
        return ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'flip':
        return RotationTransition(
          turns: Tween<double>(begin: -0.01, end: 0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'fade':
      default:
        return FadeTransition(opacity: animation, child: child);
    }
  }

  String _absoluteUrl(String url) {
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url.substring(1) : url;
    return 'http://192.168.29.184:3002/$path';
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String url;
  const _VideoPlaceholder({required this.url});

  @override
  Widget build(BuildContext context) {
    return _VideoPlayer(url: url);
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  const _VideoPlayer({required this.url});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _controller.dispose();
      _load();
    }
  }

  void _load() {
    _failed = false;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const _MediaError();
    if (!_controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.gold),
      );
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
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
