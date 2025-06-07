import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/widgets/image_circle.dart';

class MyThreadsCard extends StatefulWidget {
  final CombinedThreadPostModel post;
  final bool isMyPost;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onReport;
  final bool isReplyPage;

  const MyThreadsCard({
    super.key,
    required this.post,
    this.isMyPost = false,
    this.onEdit,
    this.onDelete,
    this.onShare,
    this.onReport,
    this.isReplyPage = false,
  });

  @override
  State<MyThreadsCard> createState() => _MyThreadsCardState();
}

class _MyThreadsCardState extends State<MyThreadsCard> {
  final HomeController homeController = Get.find<HomeController>();

  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  bool _isVideoInitialized = false;

  String _formatTimeAgo(DateTime timestamp) {
    if (timestamp.isAfter(DateTime.now())) {
      return 'Just now';
    }
    return timeago.format(timestamp, locale: 'en_short');
  }

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.post.thread.videoUrl != null &&
        widget.post.thread.videoUrl!.isNotEmpty) {
      _videoController =
          VideoPlayerController.networkUrl(
              Uri.parse(widget.post.thread.videoUrl!),
            )
            ..initialize()
                .then((_) {
                  if (mounted) {
                    setState(() {
                      _isVideoInitialized = true;
                    });
                  }
                })
                .catchError((error) {
                  debugPrint('Error initializing video: $error');
                  if (mounted) {
                    setState(() {
                      _isVideoInitialized = false;
                    });
                  }
                })
            ..addListener(_videoListener);
    }
  }

  void _videoListener() {
    if (_videoController == null) return;
    if (_videoController!.value.isPlaying && !_isPlaying) {
      if (mounted) {
        setState(() => _isPlaying = true);
      }
    } else if (!_videoController!.value.isPlaying && _isPlaying) {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar
              SizedBox(
                width: context.width * 0.12,
                child: CircleImage(url: widget.post.user.avatar_url ?? ''),
              ),
              const SizedBox(width: 10),

              // Main Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.post.user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          children: [
                            Text(
                              _formatTimeAgo(widget.post.thread.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Text(
                              " Ago",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _buildOptionsMenu(),
                          ],
                        ),
                      ],
                    ),

                    // Thread Content
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        widget.post.thread.content,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),

                    // Media Display
                    if (widget.post.thread.imageUrls.isNotEmpty)
                      _buildImageGallery(),

                    if (widget.post.thread.videoUrl != null &&
                        widget.post.thread.videoUrl!.isNotEmpty)
                      _buildVideoPlayer(),

                    // Interaction Buttons
                    _buildInteractionButtons(),
                  ],
                ),
              ),
            ],
          ),

          // Divider only if not on reply page
          if (!widget.isReplyPage)
            const Divider(
              height: 20,
              thickness: 0.5,
              indent: 60,
              endIndent: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, size: 20),
      onSelected: (String result) {
        if (result == 'edit' && widget.onEdit != null) widget.onEdit!();
        if (result == 'delete' && widget.onDelete != null) widget.onDelete!();
        if (result == 'report' && widget.onReport != null) widget.onReport!();
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
            if (widget.isMyPost)
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Edit Post'),
              ),
            if (widget.isMyPost)
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Delete Post', style: TextStyle(color: Colors.red)),
              ),
            if (!widget.isMyPost)
              const PopupMenuItem<String>(
                value: 'report',
                child: Text(
                  'Report Post',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
          ],
    );
  }

  Widget _buildImageGallery() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: context.height * 0.35,
          minHeight: context.height * 0.15,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.post.thread.imageUrls.length,
            itemBuilder: (context, index) {
              final url = widget.post.thread.imageUrls[index];
              return Padding(
                padding: EdgeInsets.only(
                  right:
                      index == widget.post.thread.imageUrls.length - 1
                          ? 0
                          : 8.0,
                ),
                child: Image.network(
                  url,
                  width: context.width * 0.75,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: context.width * 0.75,
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: context.width * 0.75,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized || _videoController == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Container(
          height: context.height * 0.25,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: context.height * 0.40,
          minHeight: context.height * 0.20,
          maxWidth: context.width * 0.75,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
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
                    _videoController!,
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
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionButtons() {
    return Row(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
               
                homeController.toggleLike(widget.post.thread.threadId);
              },
              icon: Icon(
                widget
                        .post
                        .isLikedByCurrentUser
                    ? Icons.favorite
                    : Icons.favorite_outline,
                size: 18,
                color:
                    widget
                            .post
                            .isLikedByCurrentUser
                        ? Colors.red
                        : Colors.grey[600],
              ),
            ),
            const SizedBox(width: 4),
            Text('${widget.post.thread.likesCount}'),
          ],
        ),

        const SizedBox(width: 15),

        // Comment Button
        Row(
          children: [
            IconButton(
              onPressed: () {
                Get.toNamed(RouteNamess.addReply, arguments: widget.post);
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
            ),
            const SizedBox(width: 4),
            Text('${widget.post.thread.repliesCount}'),
          ],
        ),
        const SizedBox(width: 15),

        // Share Button
        IconButton(
          onPressed: widget.onShare,
          icon: const Icon(Icons.send_outlined, size: 18),
        ),

        const Spacer(),
      ],
    );
  }
}
