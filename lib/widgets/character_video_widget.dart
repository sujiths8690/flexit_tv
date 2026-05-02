import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CharacterVideoWidget extends StatefulWidget {
  final String assetPath;

  const CharacterVideoWidget({super.key, required this.assetPath});

  @override
  State<CharacterVideoWidget> createState() => _CharacterVideoWidgetState();
}

class _CharacterVideoWidgetState extends State<CharacterVideoWidget> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.assetPath)
      ..setLooping(true)
      ..setVolume(0)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 220,
      child: _controller.value.isInitialized
          ? FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
