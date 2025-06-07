import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/profile_controller.dart';
import 'package:thread_app/controller/reply_controller.dart';
import 'package:thread_app/controller/thread_controller.dart';
import 'package:thread_app/model/combined_comment_model.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/comment_model.dart';
import 'package:thread_app/views/home/threads_card.dart';
import 'package:thread_app/widgets/image_circle.dart';
import 'package:timeago/timeago.dart' as timeago;

class ReplyPage extends StatefulWidget {
  final CombinedThreadPostModel post = Get.arguments ;

  ReplyPage({super.key});

  @override
  State<ReplyPage> createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  final CommentController controller = Get.put(CommentController());
  final ProfileController profileController = Get.put(ProfileController());
  final ThreadController threadController = Get.put(ThreadController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.listenToCommentsForThread(widget.post.thread.threadId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildOriginalPost(),
            _buildReplyInput(),
            _buildCommentsList(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.close),
      ),
      title: const Text("Replies"),
      actions: [
        // TextButton(
        //   onPressed: _addComment,
        //   child: Obx(
        //     () =>
        //         controller.isLoading.value
        //             ? const SizedBox(
        //               height: 16,
        //               width: 16,
        //               child: CircularProgressIndicator(),
        //             )
        //             : Text(
        //               "Reply",
        //               style: TextStyle(
        //                 fontWeight:
        //                     controller.commentTextController.text.isNotEmpty
        //                         ? FontWeight.bold
        //                         : FontWeight.normal,
        //               ),
        //             ),
        //   ),
        // ),

        Obx(() {
            if ( controller.isLoading.value == true) {
              return const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator.adaptive(
                ),
              );
            } else {
              return TextButton(
                onPressed: controller.commentTextController.text.isNotEmpty

                    ?  _addComment
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: threadController.canPost
                      ? Colors.blueAccent
                      : Colors.grey,
                ),
                child: Text(
                  'Reply',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: controller.commentTextController.text.isNotEmpty
                        ? Colors.blueAccent
                        : Colors.grey,
                  ),
                ),
              );
            }
          }),
      ],
    );
  }

  Widget _buildOriginalPost() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ThreadsCard(post: widget.post, isReplyPage: true),
    );
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleImage(radius: 20, url: profileController.userAvatarUrl.value),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileController.userName.value,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                TextField(
                  autofocus: true,
                  controller: controller.commentTextController,
                  onChanged: (value) => controller.update(),
                  style: const TextStyle(fontSize: 14),
                  maxLines: 5,
                  minLines: 1,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: "Reply to ${widget.post.user.name}",
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      } else if (controller.error.value.isNotEmpty) {
        return Center(child: Text('Error: ${controller.error.value}'));
      } else if (controller.comments.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No replies yet. Be the first to comment!'),
        );
      } else {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: controller.comments.length,
          itemBuilder: (context, index) {
            return _buildCommentItem(controller.comments[index]);
          },
        );
      }
    });
  }

  Widget _buildCommentItem(CombinedCommentModel combinedComment) {
    final comment = combinedComment.comment;
    final user = combinedComment.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleImage(radius: 20, url: user.avatar_url ?? ''),
          const SizedBox(width: 12),
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
                      '@${user.email.split('@')[0]}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Spacer(),
                    Text(
                      timeago.format(comment.createdAt, locale: 'en_short'),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    if (comment.updatedAt != null)
                      const Padding(
                        padding: EdgeInsets.only(left: 4.0),
                        child: Text(
                          '(Edited)',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(comment.content),
              ],
            ),
          ),
          if (controller.isCurrentUserCommentAuthor(comment.userId))
            PopupMenuButton<String>(
              onSelected: (value) => _handleCommentMenu(value, comment),
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  void _addComment() {
    if (controller.commentTextController.text.isNotEmpty) {
      controller.addComment();
      threadController.increaseReplyCount(widget.post.thread.threadId);

    }
  }

  void _handleCommentMenu(String value, CommentModel comment) {
    if (value == 'edit') {
      _showEditCommentDialog(comment);
    } else if (value == 'delete') {
      _showDeleteCommentDialog(comment);
    }
  }

  void _showEditCommentDialog(CommentModel comment) {
    final editController = TextEditingController(text: comment.content);
    final focusNode = FocusNode();

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Edit Reply',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: editController,
              focusNode: focusNode,
              autofocus: true,
              maxLines: 5,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Edit your reply...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final isUpdating = controller.isLoading.value;
              final hasChanges = editController.text.trim() != comment.content;
              final isValid = editController.text.trim().isNotEmpty;

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: isUpdating ? null : () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (editController.text.trim().isNotEmpty &&
                          editController.text.trim() != comment.content) {
                        controller.editComment(
                          comment.commentId,
                          editController.text.trim(),
                        );
                        Get.back();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        isUpdating
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text('Save'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );

    // Focus the text field and select all text
    focusNode.requestFocus();
    editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: editController.text.length,
    );
  }

  void _showDeleteCommentDialog(CommentModel comment) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Delete Reply?',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        content: const Text(
          'This reply will be permanently deleted. This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Cancel'),
          ),
          Obx(() {
            return ElevatedButton(
              onPressed:
                  controller.isLoading.value
                      ? null
                      : () {
                        controller.deleteComment(comment.commentId);
                        threadController.decreaseReplyCount(
                          widget.post.thread.threadId,
                        );

                        Get.back();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  controller.isLoading.value
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
            );
          }),
        ],
      ),
    );
  }
}
