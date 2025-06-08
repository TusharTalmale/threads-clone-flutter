import 'dart:async'; // For StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart'; // For debugPrint

// Importing your specific model classes
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart'; // Your provided UserModel
import 'package:thread_app/utils/helper.dart'; // Assumed to contain showSnackBar, showCustomSnackBar

class UserProfileController extends GetxController {
  // The ID of the user whose profile is being viewed
  late final String targetUserId;

  // Reactive variables for the target user's profile data
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final RxBool userLoading = true.obs;

  // Reactive list for the target user's posts
  final RxList<CombinedThreadPostModel> posts = <CombinedThreadPostModel>[].obs;
  final RxBool postLoading = true.obs;

  // Reactive list for replies made by the target user
  final RxList<CombinedThreadPostModel> comments = <CombinedThreadPostModel>[].obs; // To store replies
  final RxBool replyLoading = true.obs;

  final RxString errorMessage = ''.obs;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream subscriptions
  StreamSubscription? _userProfileSubscription;
  StreamSubscription? _userPostsSubscription;
  StreamSubscription? _userRepliesSubscription; 

  // Constructor to receive the userId
  UserProfileController({required this.targetUserId});

  @override
  void onInit() {
    super.onInit();
    listenToUserProfile();
    listenToUserThreads();
    
  }

  @override
  void onClose() {
    // Cancel all active stream subscriptions when the controller is closed
    _userProfileSubscription?.cancel();
    _userPostsSubscription?.cancel();
    _userRepliesSubscription?.cancel();
    super.onClose();
  }

  // --- Real-time Listener for User Profile Data ---
  void listenToUserProfile() {
    _userProfileSubscription?.cancel(); 
    userLoading.value = true;
    errorMessage.value = '';

    _userProfileSubscription = _firestore
        .collection('users')
        .doc(targetUserId)
        .snapshots() // Listen for real-time updates to the profile document
        .listen((DocumentSnapshot userDoc) async {
          debugPrint('Real-time update received for user profile: $targetUserId');
          if (userDoc.exists) {
            user.value = UserModel.fromFirestore(userDoc);
          } else {
            User? authUser = _auth.currentUser;
            if (authUser != null && authUser.uid == targetUserId) {
              user.value = UserModel(
                userId: authUser.uid,
                name: authUser.displayName ?? 'No Name',
                email: authUser.email ?? 'N/A',
                avatar_url: authUser.photoURL,
                description: '', 
              );
            } else {
              user.value = UserModel(
                userId: targetUserId,
                name: 'Unknown User',
                email: 'N/A',
                avatar_url: '',
                description: '', 
              );
              errorMessage.value = 'Profile data not found for this user.';
            }
          }
          userLoading.value = false;
        }, onError: (error) {
          debugPrint('Error listening to user profile: $error');
          errorMessage.value = 'Failed to load profile data: $error';
          userLoading.value = false;
        });
  }

  // --- Real-time Listener for User's Threads ---
  void listenToUserThreads() {
    _userPostsSubscription?.cancel(); 
    postLoading.value = true;
    posts.clear(); 

    _userPostsSubscription = _firestore
        .collection('threads')
        .where('userId', isEqualTo: targetUserId) 
        .orderBy('createdAt', descending: true)
        .snapshots() 
        .listen((QuerySnapshot threadSnapshot) async {
          debugPrint('Real-time update received for user threads. Changes: ${threadSnapshot.docChanges.length}');

          List<CombinedThreadPostModel> fetchedPosts = [];
          final String? currentViewerId = _auth.currentUser?.uid; 

          // Ensure the target user's profile is loaded before combining
          UserModel? targetUserProfile = user.value;
          if (targetUserProfile == null) {
            debugPrint('Warning: Target user profile not loaded for threads. Attempting one-time fetch.');
            DocumentSnapshot doc = await _firestore.collection('users').doc(targetUserId).get();
            if (doc.exists) {
              targetUserProfile = UserModel.fromFirestore(doc);
            } else {
              // Fallback if not found in Firestore
              targetUserProfile = UserModel(
                userId: targetUserId,
                name: 'Unknown User',
                email: 'N/A',
                avatar_url: '',
                description: '',
              );
            }
            user.value = targetUserProfile; 
          }

          // Process each document change
          for (var docChange in threadSnapshot.docChanges) {
            final thread = ThreadModel.fromFirestore(docChange.doc);
            
            // Determine if the current viewer has liked this thread
            bool isLiked = false;
            if (currentViewerId != null) {
              try {
                final likeDoc = await _firestore
                    .collection('threads')
                    .doc(thread.threadId)
                    .collection('likes')
                    .doc(currentViewerId) // Check like status for the VIEWER
                    .get();
                isLiked = likeDoc.exists;
              } catch (e) {
                debugPrint('Error checking like status for ${thread.threadId}: $e');
              }
            }

            // Ensure userModel is not null before creating CombinedThreadPostModel
            UserModel userModelForPost = targetUserProfile!; 

            final combinedModel = CombinedThreadPostModel(
              thread: thread,
              user: userModelForPost,
              isLikedByCurrentUser: isLiked, // Status for the viewer
            );

            // Update posts list based on the type of change
            if (docChange.type == DocumentChangeType.added) {
              // Insert at the correct position to maintain order by timestamp (newest at top)
              int insertIndex = posts.indexWhere((element) =>
                  element.thread.createdAt.isBefore(thread.createdAt) 
              );
              if (insertIndex == -1) {
                // If it's the oldest or list is empty, add to end (which is effectively top in reverse order)
                posts.add(combinedModel);
              } else {
                posts.insert(insertIndex, combinedModel);
              }
            } else if (docChange.type == DocumentChangeType.modified) {
              final index = posts.indexWhere((post) => post.thread.threadId == thread.threadId);
              if (index != -1) {
                posts[index] = combinedModel; 
              }
            } else if (docChange.type == DocumentChangeType.removed) {
              posts.removeWhere((post) => post.thread.threadId == thread.threadId);
            }
          }
          postLoading.value = false;
        }, onError: (error) {
          debugPrint('Error in _listenToUserThreads stream: $error');
          errorMessage.value = 'Failed to load user posts: $error';
          postLoading.value = false;
        });
  }

  // --- Real-time Listener for User's Replies (Comments) ---
  void listenToUserReplies() {
    _userRepliesSubscription?.cancel();
    replyLoading.value = true;
    comments.clear(); // Clear existing replies

    // This query fetches replies made *by* the targetUserId across all threads
    _userRepliesSubscription = _firestore
        .collectionGroup('replies') 
        .where('userId', isEqualTo: targetUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((QuerySnapshot replySnapshot) async {
          debugPrint('Real-time update received for user replies. Changes: ${replySnapshot.docChanges.length}');

          List<CombinedThreadPostModel> fetchedReplies = [];
          final String? currentViewerId = _auth.currentUser?.uid;

          // Ensure the target user's profile is loaded before combining
          UserModel? targetUserProfile = user.value;
          if (targetUserProfile == null) {
            DocumentSnapshot doc = await _firestore.collection('users').doc(targetUserId).get();
            if (doc.exists) {
              targetUserProfile = UserModel.fromFirestore(doc);
            } else {
              targetUserProfile = UserModel(
                userId: targetUserId,
                name: 'Unknown User',
                email: 'N/A',
                avatar_url: '',
                description: '',
              );
            }
            user.value = targetUserProfile;
          }

          for (var docChange in replySnapshot.docChanges) {
            final replyData = docChange.doc.data() as Map<String, dynamic>;
            
            final ThreadModel replyAsThread = ThreadModel(
              threadId: docChange.doc.id, 
              userId: targetUserId,
              content: replyData['content'] ?? 'No content',
              imageUrls: [], 
              videoUrl: null,
              likesCount: replyData['likesCount'] ?? 0, 
              repliesCount: 0, 
              createdAt: (replyData['createdAt'] as Timestamp).toDate(),
              updatedAt: (replyData['updatedAt'] as Timestamp?),
            );

            bool isLiked = false; 

            final combinedReplyModel = CombinedThreadPostModel(
              thread: replyAsThread, 
              user: targetUserProfile!,
              isLikedByCurrentUser: isLiked,
            );

            // Update comments list based on the type of change
            if (docChange.type == DocumentChangeType.added) {
              int insertIndex = comments.indexWhere((element) =>
                  element.thread.createdAt.isBefore(replyAsThread.createdAt)
              );
              if (insertIndex == -1) {
                comments.add(combinedReplyModel);
              } else {
                comments.insert(insertIndex, combinedReplyModel);
              }
            } else if (docChange.type == DocumentChangeType.modified) {
              final index = comments.indexWhere((comment) => comment.thread.threadId == replyAsThread.threadId);
              if (index != -1) {
                comments[index] = combinedReplyModel;
              }
            } else if (docChange.type == DocumentChangeType.removed) {
              comments.removeWhere((comment) => comment.thread.threadId == replyAsThread.threadId);
            }
          }
          replyLoading.value = false;
        }, onError: (error) {
          debugPrint('Error in _listenToUserReplies stream: $error');
          errorMessage.value = 'Failed to load user replies: $error';
          replyLoading.value = false;
        });
  }

  // Helper function to call from onRefresh in UI
  Future<void> refreshProfileAndThreads() async {
    listenToUserProfile();
    listenToUserThreads();
    listenToUserReplies();
  }

  // --- Thread Action Methods (can be central like in HomeController, or here) ---
  Future<void> toggleLike(String threadID) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to like a thread.');
      return;
    }

    final String userId = currentUser.uid;
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
      // The stream listeners will automatically update the UI when Firestore changes
      Get.snackbar(wasLiked ? 'Unliked' : 'Liked', 'Thread ${wasLiked ? 'unliked' : 'liked'}!', snackPosition: SnackPosition.BOTTOM);
    } on FirebaseException catch (e) {
      debugPrint('Firebase Error toggling like: ${e.code} - ${e.message}');
      Get.snackbar('Like/Unlike Failed', 'Firebase error: ${e.message}', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      debugPrint('General Error toggling like: $e');
      Get.snackbar('Like/Unlike Failed', 'An unexpected error occurred: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

}
