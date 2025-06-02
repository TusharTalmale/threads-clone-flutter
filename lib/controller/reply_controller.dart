import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/notification_controller.dart';
import 'package:thread_app/controller/profile_controller.dart';

import 'package:thread_app/model/combined_comment_model.dart';
import 'package:thread_app/model/comment_model.dart';
import 'package:thread_app/model/user_model.dart';
import 'package:thread_app/utils/helper.dart';

class CommentController extends GetxController {
  final RxList<CombinedCommentModel> comments = <CombinedCommentModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController commentTextController = TextEditingController();

  final Map<String, UserModel> _userCache = {};
  String _currentThreadId = '';

  bool isCurrentUserCommentAuthor(String commentUserId) {
    return _auth.currentUser?.uid == commentUserId;
  }

  void listenToCommentsForThread(String threadId) {
    if (_currentThreadId == threadId && !isLoading.value && comments.isNotEmpty) {
      return;
    }
    _currentThreadId = threadId;
    _startCommentListener();
  }

  void _startCommentListener() {
    isLoading.value = true;
    comments.clear();
    error.value = '';

    _firestore
        .collection('comments')
        .where('threadId', isEqualTo: _currentThreadId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen((QuerySnapshot snapshot) async {
      final List<CombinedCommentModel> fetchedComments = [];
      final List<Future<void>> futures = [];

      for (final doc in snapshot.docs) {
        final comment = CommentModel.fromFirestore(doc);
        final String userId = comment.userId;

        futures.add(() async {
          UserModel? user;
          if (_userCache.containsKey(userId)) {
            user = _userCache[userId];
          } else {
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              user = UserModel.fromFirestore(userDoc);
              _userCache[userId] = user!;
            } else {
              user = UserModel(
                userId: userId,
                name: 'Unknown User',
                email: 'N/A',
                avatar_url: '',
              );
            }
          }
          if (user != null) {
            fetchedComments.add(CombinedCommentModel(comment: comment, user: user));
          }
        }());
      }

      await Future.wait(futures);
      comments.assignAll(fetchedComments);
      isLoading.value = false;
      debugPrint('Comments updated for thread: $_currentThreadId. Total: ${comments.length}');
    }, onError: (e) {
      debugPrint('Error listening to comments: $e');
      error.value = 'Failed to load comments: ${e.toString()}';
      isLoading.value = false;
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to load comments: ${e.toString()}',
        isError: true,
      );
    });
  }

  Future<void> addComment() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      showCustomSnackBar(
        title: 'Error',
        message: 'You must be logged in to comment.',
        isError: true,
      );
      return;
    }

    final commentContent = commentTextController.text.trim();
    if (commentContent.isEmpty) {
      showCustomSnackBar(
        title: 'Validation',
        message: 'Comment cannot be empty.',
        isError: false,
      );
      return;
    }

    try {
    final threadDoc = await _firestore.collection('threads').doc(_currentThreadId).get();

   final commentRef =    await _firestore.collection('comments').add({
        'threadId': _currentThreadId,
        'userId': currentUser.uid,
        'content': commentContent,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
       final threadOwnerId = threadDoc.data()?['userId'];
    final threadData = threadDoc.data();


       if (threadOwnerId != null && threadOwnerId != currentUser.uid) {
      await Get.find<NotificationController>().sendNotification(
        recipientId: threadOwnerId,
        senderId: currentUser.uid,
        type: 'comment',
        threadId: _currentThreadId,
        replyId: commentRef.id,
        imageUrl: await _getCurrentUserImageUrl(), // Add this method to get current user's image
      );
       }

      commentTextController.clear();
      showCustomSnackBar(
        title: 'Success',
        message: 'Comment posted!',
      );

      final counterRef = FirebaseDatabase.instance
          .ref('threads')
          .child(_currentThreadId)
          .child('repliesCount');
      await counterRef.set(ServerValue.increment(1));

    } on FirebaseException catch (e) {
      debugPrint('Firebase Error posting comment: ${e.code} - ${e.message}');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to post comment: ${e.message}',
        isError: true,
      );
    } catch (e) {
      debugPrint('General Error posting comment: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
        isError: true,
      );
    }
  }

  Future<void> editComment(String commentId, String newContent) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      showCustomSnackBar(
        title: 'Error',
        message: 'You must be logged in to edit a comment.',
        isError: true,
      );
      return;
    }

    final trimmedContent = newContent.trim();
    if (trimmedContent.isEmpty) {
      showCustomSnackBar(
        title: 'Validation',
        message: 'Comment cannot be empty.',
        isError: false,
      );
      return;
    }

    try {
      final commentDoc = await _firestore.collection('comments').doc(commentId).get();
      if (!commentDoc.exists) {
        showCustomSnackBar(
          title: 'Error',
          message: 'Comment not found.',
          isError: true,
        );
        return;
      }

      final commentData = commentDoc.data();
      if (commentData?['userId'] != currentUser.uid) {
        showCustomSnackBar(
          title: 'Permission Denied',
          message: 'You can only edit your own comments.',
          isError: true,
        );
        return;
      }

      await _firestore.collection('comments').doc(commentId).update({
        'content': trimmedContent,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      showCustomSnackBar(
        title: 'Success',
        message: 'Comment updated!',
        isError: false,
      );
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error editing comment: ${e.code} - ${e.message}');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to edit comment: ${e.message}',
        isError: true,
      );
    } catch (e) {
      debugPrint('General Error editing comment: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
        isError: true,
      );
    }
  }

  Future<void> deleteComment(String commentId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      showCustomSnackBar(
        title: 'Error',
        message: 'You must be logged in to delete a comment.',
        isError: true,
      );
      return;
    }

    try {
      final commentDoc = await _firestore.collection('comments').doc(commentId).get();
      if (!commentDoc.exists) {
        showCustomSnackBar(
          title: 'Error',
          message: 'Comment not found.',
          isError: true,
        );
        return;
      }

      final commentData = commentDoc.data();
      final String? commentUserId = commentData?['userId'];
      final String? threadId = commentData?['threadId'];

      if (commentUserId != currentUser.uid) {
        showCustomSnackBar(
          title: 'Permission Denied',
          message: 'You can only delete your own comments.',
          isError: true,
        );
        return;
      }

      await _firestore.collection('comments').doc(commentId).delete();
      showCustomSnackBar(
        title: 'Success',
        message: 'Comment deleted!',
        isError: false,
      );

      if (threadId != null && threadId.isNotEmpty) {
        final counterRef = FirebaseDatabase.instance
            .ref('threads')
            .child(threadId)
            .child('repliesCount');
        await counterRef.set(ServerValue.increment(-1));
      } else {
        debugPrint('Warning: threadId missing for comment during deletion.');
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error deleting comment: ${e.code} - ${e.message}');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to delete comment: ${e.message}',
        isError: true,
      );
    } catch (e) {
      debugPrint('General Error deleting comment: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'An unexpected error occurred: $e',
        isError: true,
      );
    }
  }

  Future<String?> _getCurrentUserImageUrl() async {
  if (_auth.currentUser == null) return null;
  final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
  return userDoc.data()?['avatarUrl'];
}
}
