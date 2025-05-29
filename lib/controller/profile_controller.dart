import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thread_app/utils/env.dart';
import 'package:thread_app/utils/helper.dart';

class ProfileController extends GetxController {
  var loading = false.obs;
    var saveloading = false.obs;

  Rx<XFile?> image = Rx<XFile?>(null);
  

  //pick image
  void pickImage() async{
    loading.value = true;
    showSnackBar( "Loading",  "Image is Loading . . Do not switch tab . .  ");

    XFile?  file = await pickAndCompressImage();
          debugPrint("done got file. $file" );

    if(file != null ) image.value = file ;
    loading.value = false;

    showCustomSnackBar(title: "Success", message: "Image is Loaded successfully");    
  }

  
Future<void> updateProfile(String userId, String description) async {
  try {
    saveloading.value = true;

    final supabase = Supabase.instance.client;

    String? imageUrl;

    // If image is picked
    if (image.value != null) {
      Uint8List fileBytes = await image.value!.readAsBytes();
      String filePath =
          "profile_images/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      await supabase.storage
          .from(Env.storageBucket) 
          .uploadBinary(filePath, fileBytes);
      // Get public URL
      imageUrl = supabase.storage
          .from(Env.storageBucket)
          .getPublicUrl(filePath);

      debugPrint("Image uploaded: $imageUrl");
    }

    await supabase.from('users').update({
      'description': description,
      if (imageUrl != null) 'avatar_url': imageUrl,
    }).eq('id', userId);

    showCustomSnackBar(title: "Success", message: "Profile updated.");
  } on StorageException catch (e) {
    showSnackBar("Error", "Image upload error: ${e.message}");
  } catch (e) {
    showSnackBar("Error", "Something went wrong: $e");
  } finally {
    saveloading.value = false;
  }
}
}