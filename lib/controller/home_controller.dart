import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';
import 'dart:async';
import 'package:thread_app/utils/helper.dart'; 
class HomeController extends GetxController {
  final RxList<CombinedThreadPostModel> threads = <CombinedThreadPostModel>[].obs;
  final RxBool isLoading = true.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, UserModel> _userCache = {};
  String? _currentUserId;

  StreamSubscription? _threadsSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupAuthAndThreadListener();
  }

  @override
  void onClose() {
    _threadsSubscription?.cancel(); // Cancel the subscription when the controller is closed
    super.onClose();
  }

  
  void _setupAuthAndThreadListener() {
    _auth.authStateChanges().listen((User? user) {
      _currentUserId = user?.uid;
      if (user != null) {
        _initThreadsStream();
      } else {
        _threadsSubscription?.cancel();
        threads.clear();
        isLoading.value = false;
      }
    });
  }

  /// Initializes or reinitializes the real-time stream for threads.
  /// It listens for changes in the 'threads' collection and updates the UI.
  void _initThreadsStream() {
    _threadsSubscription?.cancel(); // Cancel any existing subscription
    isLoading.value = true;
    threads.clear(); 
    _threadsSubscription = _firestore
        .collection('threads')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (QuerySnapshot snapshot) async {
        debugPrint(
            'Real-time update received: ${snapshot.docChanges.length} changes');
        try {
          // Process changes efficiently
          final List<CombinedThreadPostModel> newThreads = [];
          final List<Future<void>> processingFutures = [];

          // Create a temporary map for efficient lookup of existing threads
          final Map<String, CombinedThreadPostModel> currentThreadsMap = {
            for (var t in threads) t.thread.threadId: t,
          };

          for (final change in snapshot.docChanges) {
            processingFutures.add(_processThreadChange(change, newThreads, currentThreadsMap));
          }

          await Future.wait(processingFutures);

          // Update the observable list. Ensure sorting if processing changes leads to out-of-order additions.
          // Since Firestore query is ordered, ensure the final list is also ordered.
          // If you always add to `newThreads` and then `assignAll`, it should maintain order.
          threads.assignAll(newThreads.toList()..sort((a, b) => b.thread.createdAt.compareTo(a.thread.createdAt)));
          isLoading.value = false;
          showCustomSnackBar(title: 'Success', message: 'Threads updated in real-time.');
        } catch (e) {
          isLoading.value = false;
          debugPrint('Error processing thread updates: $e');
          showCustomSnackBar(
              title: 'Error', message: 'Failed to update threads: $e');
        }
      },
      onError: (error) {
        isLoading.value = false;
        debugPrint('Thread stream error: $error');
        showCustomSnackBar(
            title: 'Error', message: 'Real-time thread stream failed: $error');
      },
    );
  }

  /// Processes individual document changes from the Firestore stream.
  /// It handles added, modified, and removed threads, including fetching user data
  /// and determining like status.
  Future<void> _processThreadChange(
    DocumentChange change,
    List<CombinedThreadPostModel> updatedThreadsList, // Pass list to modify
    Map<String, CombinedThreadPostModel> currentThreadsMap, // Pass map for quick lookups
  ) async {
    final thread = ThreadModel.fromFirestore(change.doc);
    final String userId = thread.userId;
    final String threadId = thread.threadId;

    switch (change.type) {
      case DocumentChangeType.added:
      case DocumentChangeType.modified:
        // Fetch user data (from cache or Firestore)
        UserModel? user = await _getUserData(userId);
        user ??= UserModel(
          userId: userId,
          name: 'Unknown User',
          email: 'N/A',
          avatar_url: '',
        );

        // Check like status for the current user
        bool hasLiked = false;
        if (_currentUserId != null) {
          try {
            final likeDoc = await _firestore
                .collection('threads')
                .doc(threadId)
                .collection('likes')
                .doc(_currentUserId)
                .get();
            hasLiked = likeDoc.exists;
          } catch (e) {
            debugPrint('Error checking like status for thread $threadId: $e');
          }
        }

        final combinedThread = CombinedThreadPostModel(
          thread: thread,
          user: user,
          isLikedByCurrentUser: hasLiked,
        );

        // Add or update in the temporary list based on type
        if (change.type == DocumentChangeType.added) {
          debugPrint('Thread added: ${thread.threadId}');
          updatedThreadsList.add(combinedThread);
        } else {
          debugPrint('Thread modified: ${thread.threadId}');
          final index = updatedThreadsList.indexWhere((t) => t.thread.threadId == threadId);
          if (index != -1) {
            updatedThreadsList[index] = combinedThread;
          } else {
            // This case might happen if a modified document was not yet in the list
            // (e.g., initial load after clearing, or a very fast modification after add)
            updatedThreadsList.add(combinedThread);
          }
        }
        break;
      case DocumentChangeType.removed:
        debugPrint('Thread removed: ${thread.threadId}');
        // Remove from the temporary list
        updatedThreadsList.removeWhere((t) => t.thread.threadId == threadId);
        break;
    }
  }

  /// Refreshes the list of threads by reinitializing the stream.
  /// This can be used for a pull-to-refresh mechanism.
  Future<void> refreshThreads() async {
    try {
      isLoading.value = true;
      threads.clear(); // Clear current data
      _initThreadsStream(); // Force a fresh load by re-initializing the stream
    } catch (e) {
      isLoading.value = false;
      debugPrint('Refresh error: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to refresh threads: $e');
    }
  }

  /// Helper method to fetch user data from cache or Firestore.
  /// Caches the user data upon successful fetch.
  Future<UserModel?> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      debugPrint('User data for $userId found in cache.');
      return _userCache[userId];
    } else {
      try {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final user = UserModel.fromFirestore(userDoc);
          _userCache[userId] = user; // Cache the fetched user data
          debugPrint('User data for $userId fetched and cached.');
          return user;
        } else {
          debugPrint('User profile for $userId not found.');
          return null;
        }
      } catch (e) {
        debugPrint('Error fetching user data for $userId: $e');
        return null;
      }
    }
  }

  /// Increases the reply count for a given thread.
  Future<void> increaseReplyCount(String threadID) async {
    try {
      await _firestore.collection('threads').doc(threadID).update({
        'repliesCount': FieldValue.increment(1),
      });
      debugPrint('Reply count for thread $threadID increased successfully!');
      // No need to manually update `threads` RxList here, as `_initThreadsStream` will
      // automatically pick up the change via the real-time listener.
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase Error increasing reply count: ${e.code} - ${e.message}');
      showSnackBar('Update Error', 'Failed to update reply count: ${e.message}');
    } catch (e) {
      debugPrint('General Error increasing reply count: $e');
      showSnackBar('Update Error', 'An unexpected error occurred: $e');
    }
  }

  /// Decreases the reply count for a given thread.
  Future<void> decreaseReplyCount(String threadID) async {
    try {
      await _firestore.collection('threads').doc(threadID).update({
        'repliesCount': FieldValue.increment(-1),
      });
      debugPrint('Reply count for thread $threadID decreased successfully!');
      // No need to manually update `threads` RxList here, as `_initThreadsStream` will
      // automatically pick up the change via the real-time listener.
    } on FirebaseException catch (e) {
      debugPrint(
          'Firebase Error decreasing reply count: ${e.code} - ${e.message}');
      showSnackBar('Update Error', 'Failed to update reply count: ${e.message}');
    } catch (e) {
      debugPrint('General Error decreasing reply count: $e');
      showSnackBar('Update Error', 'An unexpected error occurred: $e');
    }
  }

  /// Toggles the like status for a thread for the current user.
  /// It updates both the 'likes' subcollection and the 'likesCount' on the thread document.
  Future<void> toggleLike(String threadID) async {
    if (_currentUserId == null) {
      showSnackBar('Error', 'You must be logged in to like a thread.');
      return;
    }

    final String userId = _currentUserId!;
    final DocumentReference threadRef = _firestore.collection('threads').doc(threadID);
    final DocumentReference likeRef = threadRef.collection('likes').doc(userId);

    try {
      // Use a transaction for atomic updates to avoid race conditions
      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot likeDoc = await transaction.get(likeRef);
        bool wasLiked = likeDoc.exists;

        if (wasLiked) {
          transaction.delete(likeRef);
          transaction.update(threadRef, {
            'likesCount': FieldValue.increment(-1),
          });
        } else {
          transaction.set(likeRef, {'timestamp': FieldValue.serverTimestamp()});
          transaction.update(threadRef, {
            'likesCount': FieldValue.increment(1),
          });
        }
      });

      // Optimistic UI update: Find the specific thread in the RxList and update its properties.
      // This provides immediate feedback to the user without waiting for the next stream update.
      final int index = threads.indexWhere(
        (element) => element.thread.threadId == threadID,
      );
      if (index != -1) {
        final currentThread = threads[index];
        final newLikesCount = currentThread.isLikedByCurrentUser
            ? currentThread.thread.likesCount - 1
            : currentThread.thread.likesCount + 1;

        final updatedThreadModel = currentThread.thread.copyWith(
          likesCount: newLikesCount,
        );

        threads[index] = currentThread.copyWith(
          thread: updatedThreadModel,
          isLikedByCurrentUser: !currentThread.isLikedByCurrentUser, // Toggle the like status
        );
      }

      if (threads[index].isLikedByCurrentUser) {
        showCustomSnackBar(title: 'Liked', message: 'Thread liked!');
        debugPrint('User $userId liked thread $threadID');
      } else {
        showCustomSnackBar(title: 'Unliked', message: 'Thread unliked!');
        debugPrint('User $userId unliked thread $threadID');
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error toggling like: ${e.code} - ${e.message}');
      showSnackBar('Like/Unlike Failed', 'Firebase error: ${e.message}');
    } catch (e) {
      debugPrint('General Error toggling like: $e');
      showSnackBar('Like/Unlike Failed', 'An unexpected error occurred: $e');
    }
  }
}