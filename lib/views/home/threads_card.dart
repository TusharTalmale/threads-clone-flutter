import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/widgets/image_circle.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago/timeago.dart' as timeago;

class ThreadsCard extends StatelessWidget {
  final CombinedThreadPostModel post;
  final bool isReplyPage;

  const ThreadsCard({super.key, required this.post, this.isReplyPage = false});

  String _formatTimeAgo(DateTime timestamp) {
    if (timestamp.isAfter(DateTime.now())) {
      return 'Just now';
    }
    return timeago.format(timestamp, locale: 'en_short');
  }

  @override
  Widget build(BuildContext context) {
    final HomeController homeController = Get.find<HomeController>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: context.width * 0.12,
                child: CircleImage(url: post.user.avatar_url ?? ''),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post.user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatTimeAgo(post.thread.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              " Ago",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.more_horiz),
                          ],
                        ),
                      ],
                    ),
                    // Thread Content
                    Text(post.thread.content),
                    // --- Scrollable Images Section ---
                    if (post.thread.imageUrls.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight:
                                context.height *
                                0.35,
                            minHeight:
                                context.height *
                                0.15, 
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: post.thread.imageUrls.length,
                              itemBuilder: (context, index) {
                                final url = post.thread.imageUrls[index];
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right:
                                        index ==
                                                post.thread.imageUrls.length - 1
                                            ? 0
                                            : 8.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => Get.toNamed(RouteNamess.showImage , arguments: url),
                                    child: Image.network(
                                      url,
                                      width:context.width * 0.60, 
                                      fit: BoxFit.cover, 
                                      loadingBuilder: (
                                        context,
                                        child,
                                        loadingProgress,
                                      ) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: context.width * 0.60,
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value:
                                                  loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                width: context.width * 0.75,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    // --- Video Showing Feature ---
                    if (post.thread.videoUrl != null &&
                        post.thread.videoUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: context.height * 0.40,
                            minHeight: context.height * 0.20,
                            maxWidth: context.width * 0.75,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _VideoPlayerWidget(
                              videoUrl: post.thread.videoUrl!,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 10),
                    // Action Buttons (Likes, Comments, Share)
                    Row(
                      children: [
                        Obx(() {
                          final reactiveThread = homeController.threads
                              .firstWhereOrNull(
                                (t) =>
                                    t.thread.threadId == post.thread.threadId,
                              );

                          final bool isLiked =
                              reactiveThread?.isLikedByCurrentUser ??
                              post.isLikedByCurrentUser;
                          final int likesCount =
                              reactiveThread?.thread.likesCount ??
                              post.thread.likesCount;

                          return Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  homeController.toggleLike(
                                    post.thread.threadId,
                                  );
                                },
                                icon: Icon(
                                  isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_outline,
                                  size: 18,
                                  color:
                                      isLiked ? Colors.red : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text('$likesCount'),
                            ],
                          );
                        }),
                        const SizedBox(width: 15),
                        IconButton(
                          onPressed: () {
                            Get.toNamed(RouteNamess.addReply, arguments: post);
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        ),
                        const SizedBox(width: 4),
                        Text('${post.thread.repliesCount}'),
                        const SizedBox(width: 15),
                        IconButton(
                          onPressed: () {
                            // TODO: Implement share functionality
                          },
                          icon: const Icon(Icons.send_outlined),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.5, indent: 60, endIndent: 20),
        ],
      ),
    );
  }
}

// --- NEW WIDGET FOR VIDEO PLAYER ---
class _VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerWidget({required this.videoUrl});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
                // Optionally auto-play video
                // _controller.play();
                // _isPlaying = true;
              });
            }
          })
          .catchError((error) {
            debugPrint(
              'Error initializing video player for URL: ${widget.videoUrl} - $error',
            );
            if (mounted) {
              setState(() {
                _isInitialized = false;
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
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator()),
      );
    } else if (_controller.value.hasError) {
      return Container(
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
      return GestureDetector(
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
          alignment: Alignment.center,
          children: <Widget>[
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            if (!_isPlaying)
              Icon(
                Icons.play_circle_fill,
                size: 60,
                color: Colors.white.withOpacity(0.8),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).primaryColor,
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
