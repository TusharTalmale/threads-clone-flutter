import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // This seems to be for Realtime Database, make sure you need it if you're primarily using Firestore.
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thread_app/Services/navigation_service.dart';
import 'package:thread_app/utils/helper.dart'; // Assumed to contain showCustomSnackBar and pickAndCompressImage

class ThreadController extends GetxController {
  final TextEditingController addtextEditingController = TextEditingController(
    text: '',
  );

  var content = ''.obs;
  var loading = false.obs;
  var posting = false.obs;

  RxList<XFile> images = <XFile>[].obs;
  Rx<XFile?> video = Rx<XFile?>(null);

  final ImagePicker _picker = ImagePicker();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    addtextEditingController.addListener(() {
      content.value = addtextEditingController.text;
    });
  }

  @override
  void onClose() {
    addtextEditingController.dispose();
    super.onClose();
  }

  // --- Media Picking Methods ---

  Future<void> pickImages() async {
    loading.value = true;
    if (video.value != null) {
      showCustomSnackBar(
        title: 'Cannot add images',
        message: 'Clear video first to add images.',
      );
      loading.value = false;
      return;
    }
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedFiles.isNotEmpty) {
        final newImages = [...images.value, ...pickedFiles];
        if (newImages.length > 3) {
          showCustomSnackBar(
            title: 'Limit Reached',
            message: 'You can only add up to 3 images.',
          );
          images.value = newImages.sublist(
            0,
            3,
          );
        } else {
          images.value = newImages;
        }
        showCustomSnackBar(
          title: "Success",
          message: "Images loaded successfully!",
        );
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to pick images: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> pickVideo() async {
    loading.value = true;
    if (images.isNotEmpty) {
      showCustomSnackBar(
        title: 'Cannot add video',
        message: 'Clear images first to add a video.',
      );
      loading.value = false;
      return;
    }
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(
          minutes: 1,
        ),
      );
      if (pickedFile != null) {
        video.value = pickedFile;
        showCustomSnackBar(
          title: "Success",
          message: "Video loaded successfully!",
        );
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to pick video: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> takePhoto() async {
    loading.value = true;
    if (video.value != null) {
      showCustomSnackBar(
        title: 'Cannot add photos',
        message: 'Clear video first to take a photo.',
      );
      loading.value = false;
      return;
    }
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (pickedFile != null) {
        if (images.length < 3) {
          images.add(pickedFile);
          showCustomSnackBar(
            title: "Success",
            message: "Photo taken successfully!",
          );
        } else {
          showCustomSnackBar(
            title: 'Limit Reached',
            message: 'You can only add up to 3 images.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to take photo: $e');
    } finally {
      loading.value = false;
    }
  }

  Future<void> recordVideo() async {
    loading.value = true;
    if (images.isNotEmpty) {
      showCustomSnackBar(
        title: 'Cannot add video',
        message: 'Clear images first to record a video.',
      );
      loading.value = false;
      return;
    }
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(
          minutes: 1,
        ),
      );
      if (pickedFile != null) {
        video.value = pickedFile;
        showCustomSnackBar(
          title: "Success",
          message: "Video recorded successfully!",
        );
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
      showCustomSnackBar(title: 'Error', message: 'Failed to record video: $e');
    } finally {
      loading.value = false;
    }
  }

  // --- Media Removal Methods ---

  void removeImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      showCustomSnackBar(title: "Removed", message: "Image removed.");
    }
  }

  void removeVideo() {
    video.value = null;
    showCustomSnackBar(title: "Removed", message: "Video removed.");
  }

  // --- Firebase Posting Logic ---

  Future<String?> _uploadFileToFirebaseStorage(XFile file, String path) async {
    try {
      final Reference ref = _storage.ref().child(path);
      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        final metadata = SettableMetadata(contentType: file.mimeType);
        uploadTask = ref.putData(bytes, metadata);
      } else {
        File f = File(file.path);
        uploadTask = ref.putFile(f);
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('Uploaded $path, URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase Storage Error uploading $path: ${e.code} - ${e.message}',
      );
      return null;
    } catch (e) {
      debugPrint('General Error uploading $path: $e');
    
      return null;
    }
  }

  bool get canPost =>
      content.value.isNotEmpty || images.isNotEmpty || video.value != null;

  Future<void> postThread() async {
    if (!canPost) {
      showSnackBar(
        'Warning',
        'Please add some content (text, images, or video) to post.',
      );
      return;
    }

    loading.value = true;
    showCustomSnackBar(
      title: 'Posting...',
      message: 'Uploading your thread...',
    );

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        loading.value = false;
        return;
      }

      final String userId = currentUser.uid;

      posting.value = true;

      final String threadId = _firestore.collection('threads').doc().id;

      List<String> imageUrls = [];
      String? videoUrl;

      for (int i = 0; i < images.length; i++) {
        final XFile imageFile = images[i];
        final String imagePath =
            'threads/$threadId/images/image_$i.${imageFile.name.split('.').last}';
        final String? url = await _uploadFileToFirebaseStorage(
          imageFile,
          imagePath,
        );
        if (url != null) {
          imageUrls.add(url);
        } else {
          debugPrint('Failed to upload image $i for thread $threadId');
        }
      }

      if (video.value != null) {
        final XFile videoFile = video.value!;
        final String videoPath =
            'threads/$threadId/video/video.${videoFile.name.split('.').last}';
        videoUrl = await _uploadFileToFirebaseStorage(videoFile, videoPath);
        if (videoUrl == null) {
          debugPrint('Failed to upload video for thread $threadId');
        }
      }

      await _firestore.collection('threads').doc(threadId).set({
        'threadId': threadId,
        'userId': userId,
        'content': content.value,
        'imageUrls': imageUrls,
        'videoUrl': videoUrl,
        'likesCount': 0,
        'repliesCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      addtextEditingController.clear();
      images.clear();
      video.value = null;
      posting.value = false;

      Get.find<NavigationService>().backToPrevPage();
    } on FirebaseException catch (e) {
      posting.value = false;
      debugPrint('Firebase Error posting thread: ${e.code} - ${e.message}');
    } catch (e) {
      posting.value = false;
      debugPrint('General Error posting thread: $e');
    } finally {
      posting.value = false;
      loading.value = false;
    }
  }

  


  // Method to increase reply count
  Future<void> increaseReplyCount(String threadId) async {
    try {
      // Get current thread data
      final threadDoc = await _firestore.collection('threads').doc(threadId).get();
      if (threadDoc.exists) {
        final currentCount = threadDoc.data()?['repliesCount'] ?? 0;
        await _firestore.collection('threads').doc(threadId).update({
          'repliesCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error increasing reply count: $e');
    }
  }

  // Method to decrease reply count
  Future<void> decreaseReplyCount(String threadId) async {
    try {
      // Get current thread data
      final threadDoc = await _firestore.collection('threads').doc(threadId).get();
      if (threadDoc.exists) {
        final currentCount = threadDoc.data()?['repliesCount'] ?? 0;
        await _firestore.collection('threads').doc(threadId).update({
          'repliesCount': currentCount > 0 ? currentCount - 1 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error decreasing reply count: $e');
    }
  }
}