// lib/screens/media_screen.dart
//
// Shown when displayConfig.mode == DisplayMode.media.
// Supports image or video (video_player package).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../models/models.dart';
import '../services/local_media_service.dart';
import '../theme/app_theme.dart';
import '../widgets/business_brand_mark.dart';

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
  List<DisplayMediaItem> _localMediaItems = const [];
  bool _isScanningLocalMedia = false;

  List<DisplayMediaItem> get _playlist =>
      widget.mediaItems.isNotEmpty ? widget.mediaItems : _localMediaItems;

  @override
  void initState() {
    super.initState();
    _scanLocalMediaIfNeeded();
    _startTimer();
  }

  @override
  void didUpdateWidget(MediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_playlistChanged(oldWidget.mediaItems, widget.mediaItems)) {
      _index = 0;
      _scanLocalMediaIfNeeded();
      _startTimer();
    } else if (oldWidget.slideDurationSeconds != widget.slideDurationSeconds) {
      _startTimer();
    }
  }

  bool _playlistChanged(
    List<DisplayMediaItem> previous,
    List<DisplayMediaItem> next,
  ) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < previous.length; i++) {
      final oldItem = previous[i];
      final newItem = next[i];
      if (oldItem.id != newItem.id ||
          oldItem.url != newItem.url ||
          oldItem.type != newItem.type) {
        return true;
      }
    }
    return false;
  }

  void _startTimer() {
    _timer?.cancel();
    if (_playlist.length <= 1) return;
    _timer = Timer.periodic(
      Duration(seconds: widget.slideDurationSeconds),
      (_) => _advanceMedia(),
    );
  }

  void _advanceMedia() {
    if (!mounted || _playlist.length <= 1) return;
    setState(() => _index = (_index + 1) % _playlist.length);
  }

  Future<void> _scanLocalMediaIfNeeded() async {
    if (widget.mediaItems.isNotEmpty || _isScanningLocalMedia) return;
    _isScanningLocalMedia = true;
    try {
      final items = await LocalMediaService.scan();
      if (!mounted) return;
      setState(() {
        _localMediaItems = items;
        _index = 0;
      });
      _startTimer();
    } catch (_) {
      if (!mounted) return;
      setState(() => _localMediaItems = const []);
    } finally {
      _isScanningLocalMedia = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playlist = _playlist;
    final current = playlist.isNotEmpty
        ? playlist[_index % playlist.length]
        : DisplayMediaItem(
            id: 0,
            fileName: '',
            url: widget.mediaUrl,
            type: widget.mediaType,
          );
    final url = _absoluteUrl(current.url);
    final type = current.type.toLowerCase();
    final shouldPlayVideo = type == 'video' && _isPlayableVideoUrl(url);
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
            if (playlist.isEmpty)
              const _LocalMediaEmpty()
            else if (type == 'image')
              _MediaImage(url: url)
            else if (!shouldPlayVideo)
              const _MediaError()
            else
              // Video support — uncomment after adding video_player to pubspec.yaml
              // VideoPlayerWidget(url: widget.mediaUrl),
              _VideoPlaceholder(
                url: url,
                loop: playlist.length <= 1,
                onEnded: _advanceMedia,
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
    if (url.startsWith('file://')) return url;
    if (url.startsWith('/')) return Uri.file(url).toString();
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url.substring(1) : url;
    return 'http://192.168.29.184:4002/$path';
  }

  bool _isPlayableVideoUrl(String url) {
    final uri = Uri.tryParse(url);
    final path = (uri?.path ?? url).toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.m4v') ||
        path.endsWith('.mov') ||
        path.endsWith('.mkv') ||
        path.endsWith('.m3u8');
  }
}

class _MediaImage extends StatelessWidget {
  final String url;

  const _MediaImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('file://')) {
      return Image.file(
        File(Uri.parse(url).toFilePath()),
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const _MediaError(),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const _MediaError(),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  final String url;
  final bool loop;
  final VoidCallback onEnded;

  const _VideoPlaceholder({
    required this.url,
    required this.loop,
    required this.onEnded,
  });

  @override
  Widget build(BuildContext context) {
    return _VideoPlayer(
      url: url,
      loop: loop,
      onEnded: onEnded,
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  final bool loop;
  final VoidCallback onEnded;

  const _VideoPlayer({
    required this.url,
    required this.loop,
    required this.onEnded,
  });

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late VideoPlayerController _controller;
  bool _failed = false;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.loop != widget.loop) {
      _controller.removeListener(_handlePlaybackUpdate);
      _controller.dispose();
      _load();
    }
  }

  void _load() {
    _failed = false;
    _ended = false;
    _controller = widget.url.startsWith('file://')
        ? VideoPlayerController.file(File(Uri.parse(widget.url).toFilePath()))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(widget.loop)
      ..addListener(_handlePlaybackUpdate)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
      });
  }

  void _handlePlaybackUpdate() {
    if (widget.loop || _ended || !_controller.value.isInitialized) return;
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration == Duration.zero) return;
    if (position >= duration - const Duration(milliseconds: 200)) {
      _ended = true;
      widget.onEnded();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handlePlaybackUpdate);
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
      fit: BoxFit.contain,
      child: SizedBox(
        width: _controller.value.size.width,
        height: _controller.value.size.height,
        child: VideoPlayer(_controller),
      ),
    );
  }
}

class _LocalMediaEmpty extends StatelessWidget {
  const _LocalMediaEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.usb_rounded,
              color: AppTheme.whiteDim,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'No local media found',
              style: GoogleFonts.nunito(
                color: AppTheme.whiteDim,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Put images or videos in flexit/media on the pendrive.',
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
