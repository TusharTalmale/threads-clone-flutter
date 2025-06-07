import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:thread_app/model/combined_thread_post_model.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';

class MyProfileControllere extends GetxController {
  var loading = false.obs;
  var saveloading = false.obs;
  var profileLoading = true.obs;
  var userThreadsLoading = true.obs;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CombinedThreadPostModel> userPosts = <CombinedThreadPostModel>[].obs;
  final RxBool isLoadingPosts = true.obs;
  final RxString errorMessage = ''.obs;

  Rx<XFile?> image = Rx<XFile?>(null);
  var uploadedPath = "";
  RxString userName = ''.obs;
  RxString userDescription = ''.obs;
  RxString userAvatarUrl = ''.obs;
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
          .orderBy('createdAt', descending: true)
          .snapshots();

      userPosts.bindStream(_userPostsStream!.map((snapshot) {
        final List<CombinedThreadPostModel> fetchedPosts = [];
        for (var doc in snapshot.docs) {
          final thread = ThreadModel.fromFirestore(doc);
          if (profileUser.value != null) {
             fetchedPosts.add(CombinedThreadPostModel(
                thread: thread,
                user: profileUser.value!,
                isLikedByCurrentUser: false,
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

  Future<void> editPost(String threadId, String newContent, {List<String>? newImageUrls, String? newVideoUrl}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      Get.snackbar('Error', 'You must be logged in to edit posts.');
      return;
    }

    try {
      final threadDoc = await _firestore.collection('threads').doc(threadId).get();
      if (!threadDoc.exists || threadDoc.data()?['userId'] != currentUser.uid) {
        Get.snackbar('Error', 'You do not have permission to edit this post.');
        return;
      }

      Map<String, dynamic> updateData = {
        'content': newContent,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newImageUrls != null) {
        updateData['imageUrls'] = newImageUrls;
      }
      if (newVideoUrl != null) {
        updateData['videoUrl'] = newVideoUrl;
      } else if (threadDoc.data()!.containsKey('videoUrl') && newVideoUrl == null) {
         updateData['videoUrl'] = FieldValue.delete();
      }

      await _firestore.collection('threads').doc(threadId).update(updateData);

      Get.snackbar('Success', 'Post updated successfully!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Error editing post: $e");
      Get.snackbar('Error', 'Failed to update post: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }

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
            final Uri uri = Uri.parse(url);
            final String path = Uri.decodeComponent(uri.pathSegments.last);
            await storage.ref(path).delete();
          } catch (e) {
            print('Error deleting image $url from Storage: $e');
          }
        }
        if (videoUrl != null && videoUrl.isNotEmpty) {
           try {
            final Uri uri = Uri.parse(videoUrl);
            final String path = Uri.decodeComponent(uri.pathSegments.last);
            await storage.ref(path).delete();
           } catch (e) {
             print('Error deleting video $videoUrl from Storage: $e');
           }
        }
      }

      await _firestore.collection('threads').doc(threadId).delete();
      Get.snackbar('Success', 'Post and all associated data deleted!', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Error deleting post: $e");
      Get.snackbar('Error', 'Failed to delete post: $e', snackPosition: SnackPosition.BOTTOM);
    }
  }
}