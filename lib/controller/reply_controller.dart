import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/controller/notification_controller.dart';
import 'package:thread_app/controller/profile_controller.dart';

import 'package:thread_app/model/combined_comment_model.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/comment_model.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';
import 'package:thread_app/utils/helper.dart';

class CommentController extends GetxController {
  final RxList<CombinedCommentModel> comments = <CombinedCommentModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

    // New state for comments made BY the current user
  final RxList<CombinedCommentModel> currentUserReplies = <CombinedCommentModel>[].obs;
  final RxBool isLoadingCurrentUserReplies = true.obs;
  final RxString currentUserRepliesError = ''.obs;

  // New state for comments made ON the current user's posts
  final RxList<CombinedCommentModel> repliesOnMyPosts = <CombinedCommentModel>[].obs;
  final RxBool isLoadingRepliesOnMyPosts = true.obs;
  final RxString repliesOnMyPostsError = ''.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController commentTextController = TextEditingController();

  final Map<String, UserModel> _userCache = {};
  String _currentThreadId = '';
HomeController _homeController = Get.find<HomeController>();

  // Stream subscriptions to manage
  StreamSubscription<QuerySnapshot>? _currentCommentsSubscription;
  StreamSubscription<QuerySnapshot>? _currentUserRepliesSubscription;
  StreamSubscription<QuerySnapshot>? _repliesOnMyPostsSubscription;


  @override
  void onClose() {
    _currentCommentsSubscription?.cancel();
    _currentUserRepliesSubscription?.cancel();
    _repliesOnMyPostsSubscription?.cancel();
    commentTextController.dispose();
    super.onClose();
  }
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


Future<CombinedThreadPostModel?> getCombinedThreadById(
    String threadId, String userId ) async {
  try {
    // Fetch the thread document
    final threadDoc =
        await _firestore.collection('threads').doc(threadId).get();

    if (!threadDoc.exists) {
      debugPrint('Thread $threadId does not exist.');
      return null;
    }

    final thread = ThreadModel.fromFirestore(threadDoc);

    // Fetch user data (from cache or Firestore)
    UserModel? user = await _homeController.getUserData(userId);
    user ??= UserModel(
      userId: userId,
      name: 'Unknown User',
      email: 'N/A',
      avatar_url: '',
    );

    // Check like status
    bool hasLiked = false;
    if (userId != null) {
      final likeDoc = await _firestore
          .collection('threads')
          .doc(threadId)
          .collection('likes')
          .doc(userId)
          .get();
      hasLiked = likeDoc.exists;
    }

    return CombinedThreadPostModel(
      thread: thread,
      user: user,
      isLikedByCurrentUser: hasLiked,
    );
  } catch (e) {
    debugPrint('Error fetching CombinedThreadPostModel: $e');
    return null;
  }
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
      await Get.put(NotificationController()).sendNotification(
        recipientId: threadOwnerId,
        senderId: currentUser.uid,
        senderName: await _getCurrentUserName()?? "",
        type: 'comment',
        threadId: _currentThreadId,
        replyId: commentRef.id,
        imageUrl: await _getCurrentUserImageUrl(), 
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
  Future<String?> _getCurrentUserName() async {
  if (_auth.currentUser == null) return null;
  final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
  return userDoc.data()?['name'];
}

  void fetchCurrentUserReplies() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      isLoadingCurrentUserReplies.value = false;
      currentUserRepliesError.value = 'User not logged in.';
      currentUserReplies.clear();
      return;
    }

    isLoadingCurrentUserReplies.value = true;
    currentUserReplies.clear();
    currentUserRepliesError.value = '';
    _currentUserRepliesSubscription?.cancel(); // Cancel previous subscription

    _currentUserRepliesSubscription = _firestore
        .collection('comments')
        .where('userId', isEqualTo: currentUser.uid)
        .orderBy('createdAt', descending: true) // Most recent replies first
        .snapshots()
        .listen((QuerySnapshot snapshot) async {
      final List<CombinedCommentModel> fetchedReplies = [];
      final List<Future<void>> futures = [];

      for (final doc in snapshot.docs) {
        final comment = CommentModel.fromFirestore(doc);
        final String userId = comment.userId; // This will be the current user's ID

        futures.add(() async {
          UserModel? user;
          if (_userCache.containsKey(userId)) {
            user = _userCache[userId];
          } else {
            // Fetch current user's profile if not in cache (should be, but as fallback)
            final userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              user = UserModel.fromFirestore(userDoc);
              _userCache[userId] = user!;
            } else {
              user = UserModel(userId: userId, name: 'Unknown User', email: 'N/A', avatar_url: '');
            }
          }
          if (user != null) {
            fetchedReplies.add(CombinedCommentModel(comment: comment, user: user));
          }
        }());
      }

      await Future.wait(futures);
      currentUserReplies.assignAll(fetchedReplies);
      isLoadingCurrentUserReplies.value = false;
      debugPrint('Current user replies updated. Total: ${currentUserReplies.length}');
    }, onError: (e) {
      debugPrint('Error listening to current user replies: $e');
      currentUserRepliesError.value = 'Failed to load your replies: ${e.toString()}';
      isLoadingCurrentUserReplies.value = false;
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to load your replies: ${e.toString()}',
        isError: true,
      );
    });
  }


  void fetchRepliesOnMyPosts() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      isLoadingRepliesOnMyPosts.value = false;
      repliesOnMyPostsError.value = 'User not logged in.';
      repliesOnMyPosts.clear();
      return;
    }

    isLoadingRepliesOnMyPosts.value = true;
    repliesOnMyPosts.clear();
    repliesOnMyPostsError.value = '';
    _repliesOnMyPostsSubscription?.cancel(); // Cancel previous subscription

    try {
      // 1. Get all thread IDs created by the current user
      final userThreadsSnapshot = await _firestore
          .collection('threads')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final myThreadIds = userThreadsSnapshot.docs.map((doc) => doc.id).toList();

      if (myThreadIds.isEmpty) {
        isLoadingRepliesOnMyPosts.value = false;
        repliesOnMyPosts.clear();
        debugPrint('No posts found for current user, so no replies to fetch.');
        return;
      }

      // Firestore 'in' query has a limit of 10 array elements.
      // If a user has many posts, you'd need to split this into multiple queries.
      // For simplicity, we'll assume a manageable number of posts for now.
      // If `myThreadIds.length > 10`, you'd need to loop and make multiple queries.
      if (myThreadIds.length > 10) {
          debugPrint('Warning: User has more than 10 threads. "in" query might be truncated. Implement pagination for thread IDs.');
          // You would need to split `myThreadIds` into chunks of 10 and query for each chunk.
          // Example:
          // List<String> currentChunk = [];
          // for (int i = 0; i < myThreadIds.length; i++) {
          //   currentChunk.add(myThreadIds[i]);
          //   if ((i + 1) % 10 == 0 || i == myThreadIds.length - 1) {
          //     _listenToRepliesChunk(currentChunk, currentUser.uid);
          //     currentChunk = [];
          //   }
          // }
          // For this example, we'll just take the first 10.
          myThreadIds.length = 10; // Truncate for demo purposes
      }

      // 2. Listen to comments where threadId is one of the current user's thread IDs
      // AND the commenter is NOT the current user (to exclude own comments on own posts)
      _repliesOnMyPostsSubscription = _firestore
          .collection('comments')
          .where('threadId', whereIn: myThreadIds)
          .where('userId', isNotEqualTo: currentUser.uid) // Exclude comments by self
          .orderBy('userId') // Firestore requires orderBy on the field used with `isNotEqualTo`
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((QuerySnapshot snapshot) async {
        final List<CombinedCommentModel> fetchedReplies = [];
        final List<Future<void>> futures = [];

        for (final doc in snapshot.docs) {
          final comment = CommentModel.fromFirestore(doc);
          final String userId = comment.userId; // This is the ID of the commenter

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
                user = UserModel(userId: userId, name: 'Unknown User', email: 'N/A', avatar_url: '');
              }
            }
            if (user != null) {
              fetchedReplies.add(CombinedCommentModel(comment: comment, user: user));
            }
          }());
        }

        await Future.wait(futures);
        repliesOnMyPosts.assignAll(fetchedReplies);
        isLoadingRepliesOnMyPosts.value = false;
        debugPrint('Replies on my posts updated. Total: ${repliesOnMyPosts.length}');
      }, onError: (e) {
        debugPrint('Error listening to replies on my posts: $e');
        repliesOnMyPostsError.value = 'Failed to load replies on your posts: ${e.toString()}';
        isLoadingRepliesOnMyPosts.value = false;
        showCustomSnackBar(
          title: 'Error',
          message: 'Failed to load replies on your posts: ${e.toString()}',
          isError: true,
        );
      });
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error fetching user threads for replies on my posts: ${e.code} - ${e.message}');
      repliesOnMyPostsError.value = 'Failed to get your posts: ${e.message}';
      isLoadingRepliesOnMyPosts.value = false;
    } catch (e) {
      debugPrint('General Error fetching user threads for replies on my posts: $e');
      repliesOnMyPostsError.value = 'An unexpected error occurred: $e';
      isLoadingRepliesOnMyPosts.value = false;
    }
  }
}