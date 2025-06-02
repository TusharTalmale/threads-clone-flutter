import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:thread_app/model/combined_thread_post_model.dart'; // Ensure this model exists
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart'; // Ensure this model exists

class MyProfileControllere extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // RxList to hold the current user's posts, combining thread and user data
  final RxList<CombinedThreadPostModel> userPosts = <CombinedThreadPostModel>[].obs;
  final RxBool isLoadingPosts = true.obs;
  final RxString errorMessage = ''.obs;

 
  final Rx<UserModel?> profileUser = Rx<UserModel?>(null);
  final RxBool isLoadingProfileUser = true.obs;

  Stream<QuerySnapshot>? _userPostsStream;

  @override
  void onInit() {
    super.onInit();
    
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        fetchUserProfileAndPosts(user.uid);
      } else {
        profileUser.value = null;
        userPosts.clear();
        isLoadingPosts.value = false;
        isLoadingProfileUser.value = false;
        errorMessage.value = 'User not authenticated.';
      }
    });
  }

  @override
  void onClose() {
    _userPostsStream?.listen(null).cancel(); 
    super.onClose();
  }

  Future<void> fetchUserProfileAndPosts(String userId) async {
    isLoadingProfileUser.value = true;
    isLoadingPosts.value = true;
    errorMessage.value = '';

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        profileUser.value = UserModel.fromFirestore(userDoc);
      } else {
        errorMessage.value = 'User profile not found.';
        profileUser.value = null;
      }
      isLoadingProfileUser.value = false;

  
      _userPostsStream?.listen(null).cancel();

      _userPostsStream = _firestore
          .collection('threads')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true) // Order by creation time
          .snapshots(); // Listen for real-time updates

      userPosts.bindStream(_userPostsStream!.map((snapshot) {
        final List<CombinedThreadPostModel> fetchedPosts = [];
        for (var doc in snapshot.docs) {
          final thread = ThreadModel.fromFirestore(doc);
          // Combine with the fetched user profile data
          if (profileUser.value != null) {
             fetchedPosts.add(CombinedThreadPostModel(
                thread: thread,
                user: profileUser.value!,
                isLikedByCurrentUser: false, // This needs to be determined client-side or by another query if needed for initial load
             ));
          }
        }
        isLoadingPosts.value = false;
        return fetchedPosts;
      }));

    } catch (e) {
      print("Error fetching user profile and posts: $e");
      errorMessage.value = 'Failed to load profile and posts: $e';
      isLoadingProfileUser.value = false;
      isLoadingPosts.value = false;
      profileUser.value = null;
      userPosts.clear();
    }
  }

  // Method to edit an existing post
  Future<void> editPost(String threadId, String newContent, {List<String>? newImageUrls, String? newVideoUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to edit posts.');
      return;
    }

    try {
      // First, verify that the current user is the owner of the post
      final threadDoc = await _firestore.collection('threads').doc(threadId).get();
      if (!threadDoc.exists || threadDoc.data()?['userId'] != currentUser.uid) {
        Get.snackbar('Error', 'You do not have permission to edit this post.');
        return;
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(), // Add an updatedAt field
      };

      if (newImageUrls != null) {
        updateData['imageUrls'] = newImageUrls;
      }
      if (newVideoUrl != null) {
        updateData['videoUrl'] = newVideoUrl;
      } else if (threadDoc.data()!.containsKey('videoUrl') && newVideoUrl == null) {
         // If video was present and newVideoUrl is explicitly null, remove it
         updateData['videoUrl'] = FieldValue.delete();
      }

      await _firestore.collection('threads').doc(threadId).update(updateData);

      Get.snackbar('Success', 'Post updated successfully!', snackPosition: SnackPosition.BOTTOM);
      // The stream listener will automatically update userPosts list
    } catch (e) {
      print("Error editing post: $e");
      Get.snackbar('Error', 'Failed to update post: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Method to delete an existing post
  Future<void> deletePost(String threadId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to delete posts.');
      return;
    }

    try {
      final threadDoc = await _firestore.collection('threads').doc(threadId).get();
      if (!threadDoc.exists || threadDoc.data()?['userId'] != currentUser.uid) {
        Get.snackbar('Error', 'You do not have permission to delete this post.');
        return;
      }

      final likesSnapshot = await _firestore.collection('threads').doc(threadId).collection('likes').get();
      for (var doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }
      final repliesSnapshot = await _firestore.collection('threads').doc(threadId).collection('replies').get();
      for (var doc in repliesSnapshot.docs) {
        await doc.reference.delete();
      }

      final threadData = threadDoc.data();
      if (threadData != null) {
        final List<String> imageUrls = List<String>.from(threadData['imageUrls'] ?? []);
        final String? videoUrl = threadData['videoUrl'];

        final storage = FirebaseStorage.instance;
        for (String url in imageUrls) {
          try {
            // Extract path from the full download URL
            final Uri uri = Uri.parse(url);
            final String path = Uri.decodeComponent(uri.pathSegments.last); // Last segment is often the file path after /o/
            await storage.ref(path).delete();
            print('Deleted image from Storage: $path');
          } catch (e) {
            print('Error deleting image $url from Storage: $e');
            // Continue even if one image fails
          }
        }
        if (videoUrl != null && videoUrl.isNotEmpty) {
           try {
            final Uri uri = Uri.parse(videoUrl);
            final String path = Uri.decodeComponent(uri.pathSegments.last);
            await storage.ref(path).delete();
            print('Deleted video from Storage: $path');
           } catch (e) {
             print('Error deleting video $videoUrl from Storage: $e');
           }
        }
      }

      // 4. Finally, delete the thread document itself
      await _firestore.collection('threads').doc(threadId).delete();

      Get.snackbar('Success', 'Post and all associated data deleted!', snackPosition: SnackPosition.BOTTOM);
      // The stream listener will automatically update userPosts list
    } catch (e) {
      print("Error deleting post: $e");
      Get.snackbar('Error', 'Failed to delete post: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

  // Method to remove a specific image URL during post editing (frontend utility)
  void removeImageFromPost(String threadId, String imageUrl) {
    // This method would typically be used in a post editing UI to remove an image
    // from the list of images before calling `editPost`.
    // The actual Firestore update happens in `editPost`.
    // For reactive updates to the UI, you'd modify the temporary list in your UI's state management.
    // If you want a direct database removal of one image, that's also possible:
    // _firestore.collection('threads').doc(threadId).update({
    //   'imageUrls': FieldValue.arrayRemove([imageUrl])
    // });
    // Be careful with this, as it immediately updates the database.
  }
}