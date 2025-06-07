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
  StreamSubscription? _userRepliesSubscription; // For replies made by this user

  // Constructor to receive the userId
  UserProfileController({required this.targetUserId});

  @override
  void onInit() {
    super.onInit();
    // Start listening to the target user's profile data
    listenToUserProfile();
    // Start listening to the target user's threads
    listenToUserThreads();
    // Start listening to the target user's replies
    // listenToUserReplies();r
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
    _userProfileSubscription?.cancel(); // Cancel any existing subscription
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
            // Fallback if the user document doesn't exist (e.g., deleted user, or never created a profile)
            User? authUser = _auth.currentUser;
            if (authUser != null && authUser.uid == targetUserId) {
              // If it's the current authenticated user viewing their own profile, use Auth data
              user.value = UserModel(
                userId: authUser.uid,
                name: authUser.displayName ?? 'No Name',
                email: authUser.email ?? 'N/A',
                avatar_url: authUser.photoURL,
                description: '', // Default empty description
              );
            } else {
              // Default for any other user not found in 'users' collection
              user.value = UserModel(
                userId: targetUserId,
                name: 'Unknown User',
                email: 'N/A',
                avatar_url: '',
                description: '', // Default empty description
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
    _userPostsSubscription?.cancel(); // Cancel any existing subscription
    postLoading.value = true;
    posts.clear(); // Clear existing threads

    _userPostsSubscription = _firestore
        .collection('threads')
        .where('userId', isEqualTo: targetUserId) // Filter by the target user's ID
        .orderBy('createdAt', descending: true)
        .snapshots() // Listen for real-time updates
        .listen((QuerySnapshot threadSnapshot) async {
          debugPrint('Real-time update received for user threads. Changes: ${threadSnapshot.docChanges.length}');

          List<CombinedThreadPostModel> fetchedPosts = [];
          final String? currentViewerId = _auth.currentUser?.uid; // ID of the currently logged-in user (the viewer)

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
            user.value = targetUserProfile; // Update the observable profile too
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
            UserModel userModelForPost = targetUserProfile!; // Use the fetched target user's profile

            final combinedModel = CombinedThreadPostModel(
              thread: thread,
              user: userModelForPost,
              isLikedByCurrentUser: isLiked, // Status for the viewer
            );

            // Update posts list based on the type of change
            if (docChange.type == DocumentChangeType.added) {
              // Insert at the correct position to maintain order by timestamp (newest at top)
              int insertIndex = posts.indexWhere((element) =>
                  element.thread.createdAt.isBefore(thread.createdAt) // 'isBefore' because we want newest first
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
                posts[index] = combinedModel; // Replace the modified item
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
        .collectionGroup('replies') // Queries all 'replies' subcollections
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
            
            // Create a dummy ThreadModel to represent the reply for display in ThreadsCard
            // This allows us to reuse CombinedThreadPostModel and ThreadsCard.
            final ThreadModel replyAsThread = ThreadModel(
              threadId: docChange.doc.id, // Use reply ID as threadId for this representation
              userId: targetUserId,
              content: replyData['content'] ?? 'No content',
              imageUrls: [], // Assuming replies don't have images/videos in this context
              videoUrl: null,
              likesCount: replyData['likesCount'] ?? 0, // Assuming replies can have likes
              repliesCount: 0, // Replies usually don't have nested replies in this view
              createdAt: (replyData['createdAt'] as Timestamp).toDate(),
              updatedAt: (replyData['updatedAt'] as Timestamp?),
            );

            bool isLiked = false; // Implement like check for replies if your replies also have likes

            final combinedReplyModel = CombinedThreadPostModel(
              thread: replyAsThread, // This represents the reply
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
    // Calling these will trigger the stream listeners to re-evaluate/re-fetch
    listenToUserProfile();
    listenToUserThreads();
    listenToUserReplies();
  }

  // --- Thread Action Methods (can be central like in HomeController, or here) ---
  // This controller provides its own toggleLike as it's specifically managing this profile's view.
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

  // Method to edit an existing post (ownership check required in real app, and UI for this)
  Future<void> editPost(String threadId, String newContent, {List<String>? newImageUrls, String? newVideoUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to edit posts.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    // Verify ownership
    final threadDoc = await _firestore.collection('threads').doc(threadId).get();
    if (!threadDoc.exists || threadDoc.data()?['userId'] != currentUser.uid) {
      Get.snackbar('Error', 'You do not have permission to edit this post.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // TODO: Implement the actual update logic, including Storage if media changes
    // This part would involve re-uploading, deleting old, etc.
    Get.snackbar('Info', 'Edit post functionality is not fully implemented in ProfileController for now.', snackPosition: SnackPosition.BOTTOM);
  }

  // Method to delete an existing post (ownership check required in real app, and UI for this)
  Future<void> deletePost(String threadId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to delete posts.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Verify ownership
    final threadDoc = await _firestore.collection('threads').doc(threadId).get();
    if (!threadDoc.exists || threadDoc.data()?['userId'] != currentUser.uid) {
      Get.snackbar('Error', 'You do not have permission to delete this post.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // TODO: Implement the actual delete logic, including deleting subcollections and storage files
    Get.snackbar('Info', 'Delete post functionality is not fully implemented in ProfileController for now.', snackPosition: SnackPosition.BOTTOM);
  }
}
