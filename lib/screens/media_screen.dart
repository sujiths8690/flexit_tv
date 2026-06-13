// lib/screens/media_screen.dart
//
// Shown when displayConfig.mode == DisplayMode.media.
// Supports image or video (video_player package).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:video_player/video_player.dart';
import '../core/app_environment.dart';
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
  final bool isActive;
  final VoidCallback? onPlaylistCycleComplete;

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
    this.isActive = true,
    this.onPlaylistCycleComplete,
  });

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  static const _buildMarker = 'ready-image-v2';

  Timer? _timer;
  Timer? _localMediaWatcher;
  int _index = 0;
  int _mediaGeneration = 0;
  int _emptyLocalScanCount = 0;
  List<DisplayMediaItem> _localMediaItems = const [];
  final Set<String> _readyMediaUrls = {};
  final Map<String, Uint8List> _readyImageBytes = {};
  final Set<String> _failedMediaUrls = {};
  bool _isPreparingMedia = false;
  bool _isScanningLocalMedia = false;

  List<DisplayMediaItem> get _sourcePlaylist => _withoutDuplicateMedia(
        widget.mediaItems.isNotEmpty ? widget.mediaItems : _localMediaItems,
      );

  bool get _usesLocalMedia => widget.mediaItems.isEmpty;

  List<DisplayMediaItem> get _playlist {
    final source = _sourcePlaylist
        .where((item) => !_failedMediaUrls.contains(item.url))
        .toList();
    return source
        .where(
            (item) => !_isImageItem(item) || _readyMediaUrls.contains(item.url))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('Flexit media build marker: $_buildMarker');
    if (widget.mediaItems.isNotEmpty) {
      _prepareMediaThenStart();
    } else {
      _startLocalMediaWatcher();
      _scanLocalMediaIfNeeded(force: true);
    }
  }

  @override
  void didUpdateWidget(MediaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _startTimer();
      } else {
        _timer?.cancel();
        _timer = null;
        _stopLocalMediaWatcher();
      }
    }
    if (_playlistChanged(oldWidget.mediaItems, widget.mediaItems)) {
      _index = 0;
      _readyMediaUrls.clear();
      _readyImageBytes.clear();
      _failedMediaUrls.clear();
      if (widget.mediaItems.isNotEmpty) {
        _stopLocalMediaWatcher();
        _prepareMediaThenStart();
      } else {
        _startLocalMediaWatcher();
        _scanLocalMediaIfNeeded(force: true);
      }
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

  bool _sameMediaItems(
    List<DisplayMediaItem> previous,
    List<DisplayMediaItem> next,
  ) {
    if (previous.length != next.length) return false;
    for (var i = 0; i < previous.length; i++) {
      final oldItem = previous[i];
      final newItem = next[i];
      if (oldItem.fileName != newItem.fileName ||
          oldItem.url != newItem.url ||
          oldItem.type != newItem.type) {
        return false;
      }
    }
    return true;
  }

  List<DisplayMediaItem> _withoutDuplicateMedia(List<DisplayMediaItem> items) {
    final seen = <String>{};
    final deduped = <DisplayMediaItem>[];
    for (final item in items) {
      final key = _mediaIdentityKey(item);
      if (seen.add(key)) deduped.add(item);
    }
    return deduped;
  }

  String _mediaIdentityKey(DisplayMediaItem item) {
    final name = item.fileName.trim().toLowerCase();
    final path = _mediaPath(item).toLowerCase();
    final fallbackName = path.split('/').last;
    return '${item.type.toLowerCase()}:${name.isNotEmpty ? name : fallbackName}';
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = null;
    if (!widget.isActive) return;
    final playlist = _playlist;
    final playlistLength = playlist.length;
    if (playlistLength <= 1) return;
    final current = playlist[_index % playlistLength];
    if (_isVideoItem(current)) {
      _stopLocalMediaWatcher();
      debugPrint(
        'Flexit media video playing full duration: ${current.fileName}',
      );
      return;
    }
    _startLocalMediaWatcher();
    final seconds = widget.slideDurationSeconds.clamp(1, 86400);
    debugPrint(
      'Flexit media timer ($_buildMarker): ${seconds}s, index=$_index, '
      'items=$playlistLength',
    );
    _timer = Timer(
      Duration(seconds: seconds),
      _advanceMedia,
    );
  }

  void _advanceMedia() {
    if (!mounted || !widget.isActive || _playlist.length <= 1) return;
    final playlist = _playlist;
    final nextIndex = (_index + 1) % playlist.length;
    final nextItem = playlist[nextIndex];
    debugPrint(
      'Flexit media advance: $_index -> $nextIndex at '
      '${DateTime.now().toIso8601String()} file=${nextItem.fileName} '
      'type=${nextItem.type}',
    );
    setState(() => _index = nextIndex);
    if (!_isVideoItem(nextItem)) {
      _startLocalMediaWatcher();
    }
    if (nextIndex == 0) {
      widget.onPlaylistCycleComplete?.call();
    }
    _startTimer();
  }

  void _prepareMediaThenStart() {
    final generation = _mediaGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && generation == _mediaGeneration) {
        _prepareImagesForPlayback(generation);
      }
    });
  }

  Future<void> _prepareImagesForPlayback(int generation) async {
    if (_isPreparingMedia) return;
    _isPreparingMedia = true;
    _timer?.cancel();
    _timer = null;
    try {
      final source = _sourcePlaylist
          .where((item) => !_failedMediaUrls.contains(item.url))
          .toList();
      debugPrint(
        'Flexit media source=${source.length} raw=${widget.mediaItems.isNotEmpty ? widget.mediaItems.length : _localMediaItems.length}',
      );
      for (final item in source) {
        if (!mounted || generation != _mediaGeneration) return;
        if (!_isImageItem(item)) {
          _readyMediaUrls.add(item.url);
          debugPrint(
            'Flexit media non-image ready: ${item.fileName} type=${item.type}',
          );
          continue;
        }
        if (_readyMediaUrls.contains(item.url)) continue;
        debugPrint(
          'Flexit media preparing: ${item.fileName} type=${item.type} '
          'url=${item.url}',
        );
        final provider = _resizedImageProvider(
          _absoluteUrl(item.url),
          context: context,
        );
        try {
          final imageBytes = await _imageBytesFor(item);
          if (!mounted || generation != _mediaGeneration) return;
          final readyProvider = imageBytes == null
              ? provider
              : MemoryImage(imageBytes) as ImageProvider;
          await precacheImage(readyProvider, context);
          if (!mounted || generation != _mediaGeneration) return;
          setState(() {
            if (imageBytes != null) {
              _readyImageBytes[item.url] = imageBytes;
            }
            _readyMediaUrls.add(item.url);
            final playlist = _playlist;
            _index = playlist.isEmpty ? 0 : _index % playlist.length;
          });
          debugPrint(
            'Flexit media ready: ${item.fileName} bytes=${imageBytes?.length}',
          );
          if (_timer == null && _playlist.length > 1) {
            _startTimer();
          }
        } catch (e) {
          debugPrint('Flexit media prepare failed: ${item.fileName} error=$e');
          _markCurrentMediaFailed(item);
        }
      }
    } finally {
      _isPreparingMedia = false;
      if (mounted && generation == _mediaGeneration) {
        setState(() {
          final playlist = _playlist;
          _index = playlist.isEmpty ? 0 : _index % playlist.length;
        });
        _startTimer();
      }
    }
  }

  void _markCurrentMediaFailed(DisplayMediaItem item) {
    if (_failedMediaUrls.contains(item.url)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _failedMediaUrls.contains(item.url)) return;
      setState(() {
        _readyMediaUrls.remove(item.url);
        _readyImageBytes.remove(item.url);
        _failedMediaUrls.add(item.url);
        final playlist = _playlist;
        if (playlist.isNotEmpty) {
          _index = _index % playlist.length;
        }
      });
      _startTimer();
    });
  }

  void _startLocalMediaWatcher() {
    if (!widget.isActive || !_usesLocalMedia || _localMediaWatcher != null) {
      return;
    }
    _localMediaWatcher = Timer.periodic(const Duration(seconds: 3), (_) {
      _scanLocalMediaIfNeeded(force: true);
    });
  }

  void _stopLocalMediaWatcher() {
    _localMediaWatcher?.cancel();
    _localMediaWatcher = null;
  }

  Future<void> _scanLocalMediaIfNeeded({bool force = false}) async {
    if (widget.mediaItems.isNotEmpty || _isScanningLocalMedia) return;
    _isScanningLocalMedia = true;
    try {
      final items = await LocalMediaService.scan();
      if (!mounted) return;
      if (items.isEmpty && _localMediaItems.isNotEmpty) {
        _emptyLocalScanCount++;
        debugPrint(
          'Flexit local media empty scan $_emptyLocalScanCount/3; '
          'keeping current playlist',
        );
        if (_emptyLocalScanCount < 3) return;
      } else {
        _emptyLocalScanCount = 0;
      }
      if (!force && _sameMediaItems(_localMediaItems, items)) return;
      if (force && _sameMediaItems(_localMediaItems, items)) {
        if (_localMediaItems.isNotEmpty && _playlist.isEmpty) {
          _prepareMediaThenStart();
        }
        return;
      }
      _mediaGeneration++;
      _timer?.cancel();
      _timer = null;
      setState(() {
        _readyMediaUrls.clear();
        _readyImageBytes.clear();
        _failedMediaUrls.clear();
        _localMediaItems = items;
        _index = 0;
      });
      debugPrint('Flexit local media changed: ${items.length} item(s)');
      if (items.isNotEmpty) {
        _prepareMediaThenStart();
      }
    } catch (e) {
      if (!mounted) return;
      if (_localMediaItems.isNotEmpty) {
        _emptyLocalScanCount++;
        debugPrint(
          'Flexit local media scan failed $_emptyLocalScanCount/3: $e; '
          'keeping current playlist',
        );
        if (_emptyLocalScanCount < 3) return;
      }
      _mediaGeneration++;
      _timer?.cancel();
      _timer = null;
      _emptyLocalScanCount = 0;
      setState(() {
        _readyMediaUrls.clear();
        _readyImageBytes.clear();
        _failedMediaUrls.clear();
        _localMediaItems = const [];
        _index = 0;
      });
    } finally {
      _isScanningLocalMedia = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopLocalMediaWatcher();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourcePlaylist = _sourcePlaylist
        .where((item) => !_failedMediaUrls.contains(item.url))
        .toList();
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
    final isImage = _isImageItem(current);
    final shouldPlayVideo = _isVideoItem(current) && _isPlayableVideoUrl(url);
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedSwitcher(
        duration: _effectiveTransitionDuration(),
        transitionBuilder: _transitionBuilder,
        child: Stack(
          key: ValueKey('${current.id}-${current.url}'),
          fit: StackFit.expand,
          children: [
            // ── Media content ─────────────────────────────────────────
            if (playlist.isEmpty && sourcePlaylist.isNotEmpty)
              const _MediaPreparing()
            else if (playlist.isEmpty)
              const _LocalMediaEmpty()
            else if (isImage)
              _MediaImage(
                key: ValueKey(url),
                url: url,
                bytes: _readyImageBytes[current.url],
                onError: () => _markCurrentMediaFailed(current),
              )
            else if (!shouldPlayVideo)
              _MediaError(onRetryNext: () => _markCurrentMediaFailed(current))
            else
              // Video support — uncomment after adding video_player to pubspec.yaml
              // VideoPlayerWidget(url: widget.mediaUrl),
              _VideoPlaceholder(
                url: url,
                loop: playlist.length <= 1,
                isActive: widget.isActive,
                onEnded: _advanceMedia,
                onError: () => _markCurrentMediaFailed(current),
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

  Duration _effectiveTransitionDuration() {
    final slideSeconds = widget.slideDurationSeconds.clamp(1, 86400);
    final slideMillis = slideSeconds * Duration.millisecondsPerSecond;
    final requestedMillis = (widget.transitionSpeedSeconds * 1000).round();
    final cappedMillis = requestedMillis.clamp(120, slideMillis);
    return Duration(milliseconds: cappedMillis);
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
    if (url.startsWith('file:')) return url;
    if (url.startsWith('/')) return Uri.file(url).toString();
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url.substring(1) : url;
    return '${AppEnvironment.contentBaseUrl}/$path';
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

  bool _isVideoItem(DisplayMediaItem item) {
    final type = item.type.toLowerCase();
    if (type == 'video') return true;
    final path = _mediaPath(item).toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.m4v') ||
        path.endsWith('.mov') ||
        path.endsWith('.mkv') ||
        path.endsWith('.m3u8');
  }

  bool _isImageItem(DisplayMediaItem item) {
    final type = item.type.toLowerCase();
    if (type == 'image' || type == 'photo' || type == 'picture') return true;
    final path = _mediaPath(item).toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp');
  }

  String _mediaPath(DisplayMediaItem item) {
    final raw = item.url.isNotEmpty ? item.url : item.fileName;
    final uri = Uri.tryParse(raw);
    return uri?.path ?? raw;
  }

  Future<Uint8List?> _imageBytesFor(DisplayMediaItem item) async {
    final url = _absoluteUrl(item.url);
    if (!url.startsWith('file:')) return null;
    return File(Uri.parse(url).toFilePath()).readAsBytes();
  }
}

class _MediaImage extends StatelessWidget {
  final String url;
  final Uint8List? bytes;
  final VoidCallback onError;

  const _MediaImage({
    super.key,
    required this.url,
    required this.bytes,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: bytes == null
          ? _resizedImageProvider(url, context: context)
          : MemoryImage(bytes!),
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      gaplessPlayback: false,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) {
        onError();
        return const SizedBox.shrink();
      },
    );
  }
}

ImageProvider _resizedImageProvider(String url, {BuildContext? context}) {
  final mediaQuery = context == null ? null : MediaQuery.of(context);
  final decodeWidth =
      ((mediaQuery?.size.width ?? 1920) * (mediaQuery?.devicePixelRatio ?? 1))
          .round()
          .clamp(640, 1920);
  final decodeHeight =
      ((mediaQuery?.size.height ?? 1080) * (mediaQuery?.devicePixelRatio ?? 1))
          .round()
          .clamp(360, 1080);
  final provider = url.startsWith('file:')
      ? FileImage(File(Uri.parse(url).toFilePath())) as ImageProvider
      : NetworkImage(url);
  return ResizeImage(
    provider,
    width: decodeWidth,
    height: decodeHeight,
  );
}

class _VideoPlaceholder extends StatelessWidget {
  final String url;
  final bool loop;
  final bool isActive;
  final VoidCallback onEnded;
  final VoidCallback onError;

  const _VideoPlaceholder({
    required this.url,
    required this.loop,
    required this.isActive,
    required this.onEnded,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return _VideoPlayer(
      url: url,
      loop: loop,
      isActive: isActive,
      onEnded: onEnded,
      onError: onError,
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  final bool loop;
  final bool isActive;
  final VoidCallback onEnded;
  final VoidCallback onError;

  const _VideoPlayer({
    required this.url,
    required this.loop,
    required this.isActive,
    required this.onEnded,
    required this.onError,
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
    } else if (oldWidget.isActive != widget.isActive &&
        _controller.value.isInitialized) {
      if (widget.isActive) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  void _load() {
    _failed = false;
    _ended = false;
    _controller = widget.url.startsWith('file:')
        ? VideoPlayerController.file(File(Uri.parse(widget.url).toFilePath()))
        : VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..setLooping(widget.loop)
      ..addListener(_handlePlaybackUpdate)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        if (widget.isActive) {
          _controller.play();
        }
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _failed = true);
        widget.onError();
      });
  }

  void _handlePlaybackUpdate() {
    if (!widget.isActive ||
        widget.loop ||
        _ended ||
        !_controller.value.isInitialized) {
      return;
    }
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
    if (_failed) return const SizedBox.shrink();
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

class _MediaPreparing extends StatelessWidget {
  const _MediaPreparing();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          'Preparing media...',
          style: GoogleFonts.dmSans(
            color: Colors.white70,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  final VoidCallback? onRetryNext;

  const _MediaError({this.onRetryNext});

  @override
  Widget build(BuildContext context) {
    onRetryNext?.call();
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
