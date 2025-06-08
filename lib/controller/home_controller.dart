import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:thread_app/controller/notification_controller.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';
import 'dart:async';
import 'package:thread_app/utils/helper.dart';

class HomeController extends GetxController {
  final RxList<CombinedThreadPostModel> threads =
      <CombinedThreadPostModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasMore = true.obs;
  final int batchSize = 15; // Adjust as needed

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, UserModel> _userCache = {};
  String? _currentUserId;
  StreamSubscription? _threadsSubscription;
  DocumentSnapshot? _lastDocument;

  @override
  void onClose() {
    _threadsSubscription?.cancel();
    super.onClose();
  }

  void setupAuthAndThreadListener() {
    _auth.authStateChanges().listen((User? user) {
      _currentUserId = user?.uid;
      if (user != null) {
        initThreadsStream();
      } else {
        _threadsSubscription?.cancel();
        threads.clear();
        isLoading.value = false;
      }
    });
  }

  Future<void> initThreadsStream() async {
    _threadsSubscription?.cancel();
    isLoading.value = true;
    threads.clear();
    _lastDocument = null;
    hasMore.value = true;

    try {
      // Initial load of all threads
      await _loadMoreThreads();

      _threadsSubscription = _firestore
          .collection('threads')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(_handleThreadUpdates);
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error initializing threads: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to load threads: $e');
    }
  }

  Future<void> _loadMoreThreads() async {
    if (!hasMore.value || isLoading.value) return;

    isLoading.value = true;

    try {
      Query query = _firestore
          .collection('threads')
          .orderBy('createdAt', descending: true)
          .limit(batchSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        hasMore.value = false;
        isLoading.value = false;
        return;
      }

      _lastDocument = snapshot.docs.last;

      final List<CombinedThreadPostModel> newThreads = [];
      for (final doc in snapshot.docs) {
        final thread = ThreadModel.fromFirestore(doc);
        final user = await getUserData(thread.userId);

        if (user != null) {
          final hasLiked = await _checkIfLiked(thread.threadId);
          newThreads.add(
            CombinedThreadPostModel(
              thread: thread,
              user: user,
              isLikedByCurrentUser: hasLiked,
            ),
          );
        }
      }

      threads.addAll(newThreads);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error loading more threads: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to load more threads: $e',
      );
    }
  }

  Future<void> _handleThreadUpdates(QuerySnapshot snapshot) async {
    try {
      final List<Future<void>> processingFutures = [];
      final Map<String, CombinedThreadPostModel> currentThreadsMap = {
        for (var t in threads) t.thread.threadId: t,
      };

      for (final change in snapshot.docChanges) {
        processingFutures.add(_processThreadChange(change, currentThreadsMap));
      }

      await Future.wait(processingFutures);

      // Sort by createdAt after updates
      threads.sort((a, b) => b.thread.createdAt.compareTo(a.thread.createdAt));

      debugPrint('Threads updated in real-time. Total: ${threads.length}');
    } catch (e) {
      debugPrint('Error processing thread updates: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to process updates: $e',
      );
    }
  }

  Future<void> _processThreadChange(
    DocumentChange change,
    Map<String, CombinedThreadPostModel> currentThreadsMap,
  ) async {
    final thread = ThreadModel.fromFirestore(change.doc);
    final userId = thread.userId;
    final threadId = thread.threadId;

    switch (change.type) {
      case DocumentChangeType.added:
        // For new threads, add to beginning of list
        final user = await getUserData(userId);
        if (user != null) {
          final hasLiked = await _checkIfLiked(threadId);
          final combinedThread = CombinedThreadPostModel(
            thread: thread,
            user: user,
            isLikedByCurrentUser: hasLiked,
          );
          threads.insert(0, combinedThread);
        }
        break;

      case DocumentChangeType.modified:
        // Update existing thread
        final index = threads.indexWhere((t) => t.thread.threadId == threadId);
        if (index != -1) {
          final currentThread = threads[index];
          final hasLiked = await _checkIfLiked(threadId);
          threads[index] = currentThread.copyWith(
            thread: thread,
            isLikedByCurrentUser: hasLiked,
          );
        }
        break;

      case DocumentChangeType.removed:
        threads.removeWhere((t) => t.thread.threadId == threadId);
        break;
    }
  }

  Future<bool> _checkIfLiked(String threadId) async {
    if (_currentUserId == null) return false;

    try {
      final likeDoc =
          await _firestore
              .collection('threads')
              .doc(threadId)
              .collection('likes')
              .doc(_currentUserId)
              .get();
      return likeDoc.exists;
    } catch (e) {
      debugPrint('Error checking like status for thread $threadId: $e');
      return false;
    }
  }

  Future<void> refreshThreads() async {
    try {
      isLoading.value = true;
      threads.clear();
      _lastDocument = null;
      hasMore.value = true;
      await _loadMoreThreads();
    } catch (e) {
      isLoading.value = false;
      debugPrint('Refresh error: $e');
      showCustomSnackBar(
        title: 'Error',
        message: 'Failed to refresh threads: $e',
      );
    }
  }

  Future<UserModel?> getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final user = UserModel.fromFirestore(userDoc);
        _userCache[userId] = user;
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data for $userId: $e');
      return null;
    }
  }

  Future<void> increaseReplyCount(String threadID) async {
    try {
      await _firestore.collection('threads').doc(threadID).update({
        'repliesCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error increasing reply count: $e');
    }
  }

  Future<void> decreaseReplyCount(String threadID) async {
    try {
      await _firestore.collection('threads').doc(threadID).update({
        'repliesCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Error decreasing reply count: $e');
    }
  }

  Future<void> toggleLike(String threadID) async {
    if (_currentUserId == null) {
      showCustomSnackBar(
        title: 'Error',
        message: 'You must be logged in to like a thread.',
      );
      return;
    }

    try {
      final threadRef = _firestore.collection('threads').doc(threadID);
      final likeRef = threadRef.collection('likes').doc(_currentUserId);

      await _firestore.runTransaction((transaction) async {
        final likeDoc = await transaction.get(likeRef);
        final wasLiked = likeDoc.exists;

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

      // Update local state
      final index = threads.indexWhere((t) => t.thread.threadId == threadID);
      if (index != -1) {
        final currentThread = threads[index];
        var newLikesCount;
        if (currentThread.isLikedByCurrentUser) {
          newLikesCount = currentThread.thread.likesCount - 1;
        } else {
          newLikesCount = currentThread.thread.likesCount + 1;
          Get.put(NotificationController()).sendNotification(senderId: _currentUserId! , recipientId: currentThread.user.userId , senderName: currentThread.user.name , type:"like" , imageUrl : currentThread.user.avatar_url , threadId : currentThread.thread.threadId , );
          
        }

        threads[index] = currentThread.copyWith(
          thread: currentThread.thread.copyWith(likesCount: newLikesCount),
          isLikedByCurrentUser: !currentThread.isLikedByCurrentUser,
        );
      }
    } catch (e) {
      debugPrint('Error toggling like: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to toggle like: $e');
    }
  }

  Future<void> loadMore() async {
    await _loadMoreThreads();
  }
}
