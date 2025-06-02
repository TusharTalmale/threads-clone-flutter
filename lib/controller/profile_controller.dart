import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:thread_app/utils/helper.dart';
import 'package:flutter/foundation.dart';

class ProfileController extends GetxController {
  var loading = false.obs;
  var saveloading = false.obs;
  var profileLoading = true.obs;

  Rx<XFile?> image = Rx<XFile?>(null);
  var uploadedPath = "";
  RxString userName = ''.obs;
  RxString userDescription = ''.obs;
  RxString userAvatarUrl = ''.obs;


  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  @override
  void onInit() {
    super.onInit();
    fetchUserProfileData();
  }

  //pick image
  void pickImage() async {
    loading.value = true;
    showSnackBar("Loading", "Image is Loading . . Do not switch tab . .  ");

    XFile? file = await pickAndCompressImage();
    debugPrint("done got file. $file");

    if (file != null) image.value = file;
    loading.value = false;

    showCustomSnackBar(
      title: "Success",
      message: "Image is Loaded successfully",
    );
  }

  Future<void> updateProfile(String description) async {
    try {
      saveloading.value = true;

      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception("User not logged in.");
      }
      final String userId = currentUser.uid;
      debugPrint("Firebase userId: $userId");

      if (image.value != null) {
        debugPrint("Uploading image: ${image.value?.path}");

        String filePath = 'users/$userId/profile.jpg';
        final Reference ref = _storage.ref().child(filePath);

        UploadTask uploadTask;

        if (kIsWeb) {
          final bytes = await image.value!.readAsBytes();
          final metadata = SettableMetadata(contentType: 'image/jpeg');
          uploadTask = ref.putData(bytes, metadata);
        } else {
          File file = File(image.value!.path);
          uploadTask = ref.putFile(file);
        }

        final TaskSnapshot snapshot = await uploadTask;
        uploadedPath = await snapshot.ref.getDownloadURL();

        debugPrint("Image uploaded: $uploadedPath");
      }

      final Map<String, dynamic> updateData = {'description': description};
      if (uploadedPath.isNotEmpty) {
        updateData['avatar_url'] = uploadedPath;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .set(updateData, SetOptions(merge: true));
      Get.back();

      showCustomSnackBar(title: "Success", message: "Profile updated.");
    } on FirebaseException catch (e) {
      debugPrint("Firebase Error: ${e.code} - ${e.message}");
      showSnackBar("Error", "Operation failed: ${e.message}");
    } catch (e) {
      debugPrint("General Error: ${e.toString()}");
      showSnackBar("Error", "Something went wrong: $e");
    } finally {
      saveloading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user profile from Firestore: $e");
      return null;
    }
  }

  Future<void> fetchUserProfileData() async {
    profileLoading.value = true;
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        final Map<String, dynamic>? profileData = await getUserProfile(
          currentUser.uid,
        );

        if (profileData != null) {
          // Update reactive variables with data from Firestore
          userName.value =
              profileData['name'] ?? currentUser.displayName ?? 'No Name';
          userDescription.value =
              profileData['description'] ?? 'No description yet.';
          userAvatarUrl.value = profileData['avatar_url'] ?? '';
        } else {
          // If no specific profile document exists, use data from Firebase Auth
          userName.value = currentUser.displayName ?? 'No Name';
          userDescription.value = 'No description yet.';
          userAvatarUrl.value =
              currentUser.photoURL ?? ''; // Use Auth photoURL if available
        }
      } else {
        userName.value = 'Guest';
        userDescription.value = 'Please log in to see your profile.';
        userAvatarUrl.value = '';
      }
    } catch (e) {
      debugPrint("Failed to fetch profile data: $e");
      showSnackBar("Error", "Failed to load profile data: ${e.toString()}");
      userName.value = 'Error';
      userDescription.value = 'Could not load profile.';
      userAvatarUrl.value = '';
    } finally {
      profileLoading.value = false;
    }
  }
}
