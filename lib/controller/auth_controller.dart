import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/Services/storage_service.dart';
import 'package:thread_app/utils/helper.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';


class AuthController extends GetxController {
  var registerLoading = false.obs;
  var loginLoading = false.obs;
  var logoutLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> register(String name, String email, String password) async {
    try {
      registerLoading.value = true;
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      registerLoading.value = false;

      if (userCredential.user != null) {
        final User? user = userCredential.user;

        // 1. Update display name in Firebase Auth (optional, but good)
        await user!.updateDisplayName(name);

        // 2. Add user profile data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'userId': user.uid,
          'name': name,
          'email': email,
          'description': null,
          'avatarId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await StorageService.saveUserSession({
          'uid': user.uid,
          'email': user.email,
          'name': name,
        });
        Get.offAllNamed(RouteNamess.home);
      }
    } on FirebaseAuthException catch (e) {
      registerLoading.value = false;
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'The account already exists for that email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage =
              e.message ?? 'An unknown error occurred during registration.';
      }
      showSnackBar("Registration Failed", errorMessage);
    } catch (e) {
      registerLoading.value = false;
      showSnackBar(
        "Registration Failed",
        "An unexpected error occurred: ${e.toString()}",
      );
    }
  }

  Future<void> login(String email, String password) async {
    try {
      loginLoading.value = true;

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);
      loginLoading.value = false;

      if (userCredential.user != null) {
        final User? user = userCredential.user;

        // Fetch user profile from Firestore after successful login
        final DocumentSnapshot userProfileDoc =
            await _firestore.collection('users').doc(user!.uid).get();
        if (userProfileDoc.exists) {
          final Map<String, dynamic> profileData =
              userProfileDoc.data() as Map<String, dynamic>;
          // Save fetched profile data to GetStorage
          await StorageService.saveUserSession({
            'uid': user.uid,
            'email': user.email,
            'name': profileData['name'],
          });
        }

        Get.offAllNamed(RouteNamess.home);
      }
    } on FirebaseAuthException catch (e) {
      loginLoading.value = false;
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = e.message ?? 'An unknown error occurred during login.';
      }
      showSnackBar("Login Failed", errorMessage);
    } catch (e) {
      loginLoading.value = false;
    
    }
  }

  Future<void> logout() async {
    try {
      logoutLoading.value = true;
      await _auth.signOut();
      await StorageService.clearUserSession();

      logoutLoading.value = false;

      await StorageService.session.erase();

      Get.offAllNamed(RouteNamess.login);
      showSnackBar("Logged Out", "You have been signed out successfully.");
    } catch (e) {
      logoutLoading.value = false;
      showSnackBar("Logout Failed", "Please try again. Error: ${e.toString()}");
    }
  }


Future<void> loginWithGoogle() async {
  try {
    loginLoading.value = true;

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      loginLoading.value = false;
      showSnackBar("Cancelled", "Google sign-in was cancelled.");
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential =
        await _auth.signInWithCredential(credential);
    loginLoading.value = false;

    final User? user = userCredential.user;
    if (user != null) {
      // Check if user exists in Firestore
      final docRef = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Create profile for first-time login via Google
        await docRef.set({
          'userId': user.uid,
          'name': user.displayName ?? "",
          'email': user.email ?? "",
          'description': null,
          'avatarId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await StorageService.saveUserSession({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? "",
      });

      Get.offAllNamed(RouteNamess.home);
    }
  } catch (e) {
    loginLoading.value = false;
    showSnackBar("Google Login Failed", e.toString());
  }
}
Future<void> registerWithGoogle() async {
  await loginWithGoogle();
}

  // Example of fetching a user's profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user profile: $e");
      return null;
    }
  }

  // Example of updating user profile
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? description,
    String? avatarId,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (avatarId != null) updates['avatarId'] = avatarId;

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update(updates);
        showSnackBar("Success", "Profile updated successfully.");
      }
    } catch (e) {
      showSnackBar("Error", "Failed to update profile: ${e.toString()}");
    }
  }
}
