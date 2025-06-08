import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';

class VideoPreviewPlayer extends StatefulWidget {
  final XFile videoFile;
  final VoidCallback onRemove;

  const VideoPreviewPlayer({
    super.key,
    required this.videoFile,
    required this.onRemove,
  });

  @override
  State<VideoPreviewPlayer> createState() => _VideoPreviewPlayerState();
}

class _VideoPreviewPlayerState extends State<VideoPreviewPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    _controller = kIsWeb
        ? VideoPlayerController.network(widget.videoFile.path)
        : VideoPlayerController.file(File(widget.videoFile.path));

    _controller.initialize().then((_) {
      setState(() => _isInitialized = true);
      _controller.setLooping(true);
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
    return AspectRatio(
      aspectRatio: _isInitialized ? _controller.value.aspectRatio : 1.0,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          _isInitialized
              ? VideoPlayer(_controller)
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            right: 5,
            top: 5,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
