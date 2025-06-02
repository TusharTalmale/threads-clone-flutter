import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/route_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'dart:io' as io show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img_pkg;

void showSnackBar(String title, String message) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.grey[900],
    colorText: const Color.fromARGB(255, 240, 239, 239),
    snackPosition: SnackPosition.BOTTOM,
    margin: EdgeInsets.all(12),
    borderRadius: 10,
    titleText: Text(
      title,
      style: TextStyle(
        color: const Color.fromARGB(255, 210, 20, 20),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  );
}

void showCustomSnackBar({required String title, required String message , bool isError =false}) {
  Get.snackbar(
    title,
    message,
    backgroundColor: Colors.grey[900],
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    borderRadius: 12,
    duration: Duration(seconds: 3),
    isDismissible: true,
    forwardAnimationCurve: Curves.easeOut,
    reverseAnimationCurve: Curves.easeIn,
    animationDuration: Duration(milliseconds: 400),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    titleText: Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(color: Colors.white, fontSize: 14),
    ),
  );
}

/// Pick and compress an image
Future<File?> pickImageFromGallary() async {
  try {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      showSnackBar("No Image", "Image picking was cancelled.");
      return null;
    }

    final File imageFile = File(pickedFile.path);
    final File? compressed = await _compressImage(imageFile);

    if (compressed == null) {
      showSnackBar("Error", "Failed to compress image.");
      return null;
    }

    debugPrint("Original: ${await imageFile.length()} bytes");

    debugPrint("Compressed: ${await compressed.length()} bytes");
    
    // Delete original image after successful compression
    if (await imageFile.exists()) {
      await imageFile.delete();
      debugPrint("Original image deleted.");
    }

    showCustomSnackBar(title: "Success",message:  "Image compressed successfully.");
    return compressed;
  } catch (e) {
    debugPrint("Error: $e");
    showSnackBar("Exception", e.toString());
    return null;
  }
}

/// Compress image 
Future<File?> _compressImage(File file) async {
  try {
    final uuid = Uuid();
    final targetPath = "${file.parent.path}/${uuid.v4()}.jpg";

    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      format: CompressFormat.jpeg,
    );

    return result != null ? File(result.path) : null;
  } catch (e) {
    debugPrint('Compression error: $e');
    return null;
  }
}

  Future<XFile?> pickAndCompressImage() async {
  try {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    debugPrint("image Picked.");
    if (picked == null) {
      debugPrint("No image selected.");
      return null;
    }

    if (kIsWeb) {
      debugPrint("Web selected.");
      // ─── WEB ───────────────────────────────────────────────────────────────
      final originalBytes = await picked.readAsBytes();
      // Decode, compress, re-encode
      debugPrint("before decode , compress selected.");
      final decoded = img_pkg.decodeImage(originalBytes);
      if (decoded == null) throw Exception("Failed to decode image on Web.");
      debugPrint("before compressbyt.");
      final compressedBytes = img_pkg.encodeJpg(decoded, quality: 70);
      debugPrint("After compressbyt.");

      // Wrap back into an XFile for consistency
     return XFile.fromData(
        compressedBytes,
        name: "${const Uuid().v4()}.jpg",
        mimeType: 'image/jpeg',
      );

    } else {

      // ─── MOBILE (Android / iOS) ────────────────────────────────────────────
      final io.File file = io.File(picked.path);
      final String targetPath = "${file.parent.path}/${const Uuid().v4()}.jpg";

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 70,
        format: CompressFormat.jpeg,
      );

      if (result == null) throw Exception("Compression failed on mobile.");

      // Optionally delete the original
      try {
        await file.delete();
        debugPrint("Original file deleted.");
      } catch (_) {}

    return result ;
    }
  } catch (e) {
    debugPrint("Error during pick/compress: $e");
    return null;
  }
}
