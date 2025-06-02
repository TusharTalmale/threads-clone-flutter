import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart'; // For debugPrint and showCustomSnackBar
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';

// Import your custom models

import 'package:thread_app/utils/helper.dart'; // Assuming showCustomSnackBar is here

class HomeController extends GetxController {
  // Reactive list to hold all fetched threads combined with user data
  final RxList<CombinedThreadPostModel> threads = <CombinedThreadPostModel>[].obs;

  // Reactive boolean to indicate if data is currently being loaded
  final RxBool isLoading = true.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  final Map<String, UserModel> _userCache = {};
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
        _currentUserId = _auth.currentUser?.uid;
_auth.authStateChanges().listen((User? user) {
      _currentUserId = user?.uid;
      // You might want to re-fetch threads if the user logs in/out
      // or if the like status depends heavily on the current user.
      // For now, we'll rely on the manual update in toggleLike.
    });
    fetchThreads();
  }

  // Method to fetch all threads and their respective user data
  Future<void> fetchThreads() async {
    isLoading.value = true; // Set loading state to true
    threads.clear(); // Clear existing threads before fetching new ones

    try {
      // 1. Fetch all thread documents from the 'threads' collection
      // Order by creation time, newest first
      final QuerySnapshot threadSnapshot = await _firestore
          .collection('threads')
          .orderBy('createdAt', descending: true)
          .get();

      // List to hold futures for fetching user data concurrently
      final List<Future<void>> fetchFutures = [];

      // Loop through each thread document
      for (final doc in threadSnapshot.docs) {
        final thread = ThreadModel.fromFirestore(doc);
        final String userId = thread.userId;
        final String threadId = thread.threadId;
        fetchFutures.add(() async {
          UserModel? user;
          if (_userCache.containsKey(userId)) {
            user = _userCache[userId];
            debugPrint('User data for $userId found in cache.');
          } else {
            // If not in cache, fetch user data from 'users' collection
            final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              user = UserModel.fromFirestore(userDoc);
              _userCache[userId] = user!; // Cache the fetched user data
              debugPrint('User data for $userId fetched and cached.');
            } else {
              // Handle case where user profile might not exist (e.g., deleted user)
              debugPrint('User profile for $userId not found. Using default.');
              user = UserModel(
                userId: userId,
                name: 'Deleted User', // Default name for missing user
                email: 'N/A',
                avatar_url: '', // Default empty avatar (using fixed field name)
              );
            }
          }
              bool hasLiked = false;
          if (_currentUserId != null) {
            final likeDoc = await _firestore
                .collection('threads')
                .doc(threadId)
                .collection('likes')
                .doc(_currentUserId)
                .get();
            hasLiked = likeDoc.exists;
          }


          // If both thread and user data are available, combine and add to threads list
          if (user != null) {
            threads.add(CombinedThreadPostModel(thread: thread, user: user,  isLikedByCurrentUser: hasLiked,));
          }
        }()); // Call the async function immediately
      }

      // Wait for all user data fetching operations to complete
      await Future.wait(fetchFutures);

      debugPrint('Fetched ${threads.length} threads successfully.');
      showCustomSnackBar(title: 'Success', message: 'Threads loaded.');

    } on FirebaseException catch (e) {
      debugPrint('Firebase Error fetching threads: ${e.code} - ${e.message}');
      showCustomSnackBar(title: 'Error', message: 'Failed to load threads: ${e.message}');
    } catch (e) {
      debugPrint('General Error fetching threads: $e');
      showCustomSnackBar(title: 'Error', message: 'An unexpected error occurred: $e');
    } finally {
      isLoading.value = false; // Set loading state to false regardless of success or failure
    }
  }

  

  Future<void> increaseReplyCount(String threadID) async {
    try {
      await _firestore.collection('threads').doc(threadID).update({
        'repliesCount': FieldValue.increment(1),
      });
      debugPrint('Reply count for thread $threadID increased successfully!');
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error increasing reply count: ${e.code} - ${e.message}');
      showSnackBar('Update Error', 'Failed to update reply count: ${e.message}');
    } catch (e) {
      debugPrint('General Error increasing reply count: $e');
      showSnackBar('Update Error', 'An unexpected error occurred: $e');
    }
  }

  Future<void> decreaseReplyCount(String threadID) async {
    try {
      await _firestore.collection('threads').doc(threadID).update({
        'repliesCount': FieldValue.increment(-1),
      });
      debugPrint('Reply count for thread $threadID decreased successfully!');
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error decreasing reply count: ${e.code} - ${e.message}');
      showSnackBar('Update Error', 'Failed to update reply count: ${e.message}');
    } catch (e) {
      debugPrint('General Error decreasing reply count: $e');
      showSnackBar('Update Error', 'An unexpected error occurred: $e');
    }
  }

  /// Toggles the like status of a thread for the current user.
  /// If the user has already liked the thread, it unlikes it; otherwise, it likes it.
  Future<void> toggleLike(String threadID) async {
    if (_currentUserId == null) {
      showSnackBar('Error', 'You must be logged in to like a thread.');
      return;
    }

    final String userId = _currentUserId!;
    final DocumentReference threadRef = _firestore.collection('threads').doc(threadID);
    final DocumentReference likeRef = threadRef.collection('likes').doc(userId);

    try {
      final DocumentSnapshot likeDoc = await likeRef.get();
      bool wasLiked = likeDoc.exists;

      await _firestore.runTransaction((transaction) async {
        if (wasLiked) {
          transaction.delete(likeRef);
          transaction.update(threadRef, {
            'likesCount': FieldValue.increment(-1),
          });
        } else {
          transaction.set(likeRef, {
            'timestamp': FieldValue.serverTimestamp(),
          });
          transaction.update(threadRef, {
            'likesCount': FieldValue.increment(1),
          });
        }
      });
        // --- Reactive UI Update ---
      // Find the specific thread in the RxList and update its properties
      final int index = threads.indexWhere((element) => element.thread.threadId == threadID);
      if (index != -1) {
        final currentThread = threads[index];
        final newLikesCount = wasLiked ? currentThread.thread.likesCount - 1 : currentThread.thread.likesCount + 1;

        // Create a new ThreadModel with updated likesCount
        final updatedThreadModel = currentThread.thread.copyWith(
          likesCount: newLikesCount,
        );

        // Update the CombinedThreadPostModel in the list
        threads[index] = currentThread.copyWith(
          thread: updatedThreadModel,
          isLikedByCurrentUser: !wasLiked, // Toggle the like status
        );
      }
      // --- End Reactive UI Update ---

      if (wasLiked) {
        showCustomSnackBar(title: 'Unliked', message: 'Thread unliked!');
        debugPrint('User $userId unliked thread $threadID');
      } else {
        showCustomSnackBar(title: 'Liked', message: 'Thread liked!');
        debugPrint('User $userId liked thread $threadID');
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
