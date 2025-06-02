import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/profile/post_show_controller.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:thread_app/views/profile/mythedcard.dart'; 

class ProfileThreadsView extends StatefulWidget {
  final String? viewingUserId; 

  ProfileThreadsView({super.key, this.viewingUserId});

  @override
  State<ProfileThreadsView> createState() => _ProfileThreadsViewState();
}

class _ProfileThreadsViewState extends State<ProfileThreadsView> {
  final MyProfileControllere profileController = Get.put(MyProfileControllere());
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      profileController.fetchUserProfileAndPosts(widget.viewingUserId!);
    });
  }
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (profileController.isLoadingPosts.value && profileController.profileUser.value?.userId == widget.viewingUserId) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }

      final filteredPosts = profileController.userPosts.where(
        (post) => post.user.userId == widget.viewingUserId
      ).toList();

      if (filteredPosts.isEmpty) {
        return const Center(child: Text('No posts found for this user.', style: TextStyle(color: Colors.white70)));
      }

      final String? currentLoggedInUserId = FirebaseAuth.instance.currentUser?.uid;

      return ListView.builder(
        padding: const EdgeInsets.all(0),
        itemCount: filteredPosts.length,
        itemBuilder: (context, index) {
          final post = filteredPosts[index];
          final bool isMyPost = currentLoggedInUserId != null && post.user.userId == currentLoggedInUserId;

          return MyThreadsCard(
            post: post,
            isMyPost: isMyPost,
            onEdit: isMyPost ? () => _showEditDialog(context, post) : null,
            onDelete: isMyPost ? () => _confirmDelete(context, post) : null,
            onLike: () {
              // TODO: Implement like logic
              Get.snackbar('Like Action', 'Tapped like on post by ${post.user.name}');
            },
            onComment: () {
              Get.snackbar('Comment Action', 'Tapped comment on post by ${post.user.name}');
            },
            onShare: () {
              Get.snackbar('Share Action', 'Tapped share on post by ${post.user.name}');
            },
            onReport: isMyPost ? null : () { 
              Get.snackbar('Report Action', 'Tapped report on post by ${post.user.name}');
            },
          );
        },
      );
    });
  }

  // --- Dialogs for Edit/Delete (Can be extracted to a utility class or mixin) ---
  void _showEditDialog(BuildContext context, CombinedThreadPostModel post) {
    final TextEditingController _editController = TextEditingController(text: post.thread.content);
    // You might also need controllers for image/video URLs if editing media is supported
    Get.dialog(
      AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(hintText: 'New post content'),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_editController.text.isNotEmpty) {
                profileController.editPost(
                  post.thread.threadId,
                  _editController.text.trim(),
                  // Pass newImageUrls, newVideoUrl from your editing UI
                );
                Get.back();
              } else {
                Get.snackbar('Error', 'Post content cannot be empty.');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CombinedThreadPostModel post) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              profileController.deletePost(post.thread.threadId);
              Get.back();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}