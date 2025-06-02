import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/reply_controller.dart';
import 'package:thread_app/widgets/image_circle.dart'; // Your custom widget for circular images
import 'package:timeago/timeago.dart' as timeago; // For formatting timestamps

class CommentPage extends StatelessWidget {
  final String threadId; // The ID of the thread to load comments for

  CommentPage({super.key}) : threadId = Get.arguments as String; // Get threadId from arguments

  // Initialize the CommentController and fetch comments
  final CommentController commentController = Get.put(CommentController());

  @override
  Widget build(BuildContext context) {
    // Call fetchCommentsForThread in build, or use onInit() in controller
    // If using onInit, ensure the threadId is passed before controller initialization.
    // For simplicity here, we'll call it once the page loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      commentController.listenToCommentsForThread(threadId);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (commentController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              } else if (commentController.error.value.isNotEmpty) {
                return Center(child: Text(commentController.error.value));
              } else if (commentController.comments.isEmpty) {
                return const Center(child: Text('No comments yet. Be the first to comment!'));
              } else {
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: commentController.comments.length,
                  itemBuilder: (context, index) {
                    final combinedComment = commentController.comments[index];
                    final comment = combinedComment.comment;
                    final user = combinedComment.user;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleImage(url: user.avatar_url ?? ''), // Display commenter's avatar
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '@${user.email.split('@')[0]}', // Display username from email
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Text(
                                      timeago.format(comment.createdAt, locale: 'en_short'),
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(comment.content),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            }),
          ),
          // Comment Input Section
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController.commentTextController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none, // No border for a cleaner look
                      ),
                      filled: true,
                      fillColor: Colors.grey[200], // Light grey background
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    ),
                    maxLines: null, // Allow multiline input
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () {
                  },
                  mini: true, // Make it a small button
                  child: const Icon(Icons.send),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}