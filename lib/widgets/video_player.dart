
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            // Optionally auto-play video
            // _controller.play();
            // _isPlaying = true;
          });
        }
      }).catchError((error) {
        debugPrint('Error initializing video player for URL: ${widget.videoUrl} - $error');
        if (mounted) {
          setState(() {
            _isInitialized = false;
            // You might want to show a more explicit error message in the UI
          });
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        // Ensure this container gets its size from the parent ConstrainedBox
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(), // Show loading indicator
        ),
      );
    } else if (_controller.value.hasError) {
      return Container(
        // Ensure this container gets its size from the parent ConstrainedBox
        color: Colors.red[100],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(
                'Could not load video.',
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector( // Allow tapping anywhere on the video to play/pause
        onTap: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
              _isPlaying = false;
            } else {
              _controller.play();
              _isPlaying = true;
            }
          });
        },
        child: Stack(
          alignment: Alignment.center, // Center controls and progress
          children: <Widget>[
            // AspectRatio ensures the video maintains its original aspect ratio
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            // Play/Pause button overlay (only shown when not playing)
            if (!_isPlaying) // Show button if paused or not started
              Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white.withOpacity(0.8),
              ),
            Positioned( // Progress indicator at the bottom
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).primaryColor, // Use app's primary color
                  bufferedColor: Colors.white54,
                  backgroundColor: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
