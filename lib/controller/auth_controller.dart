import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/Services/storage_service.dart';
import 'package:thread_app/Services/supabase_service.dart';
import 'package:thread_app/utils/helper.dart';
import 'package:thread_app/utils/storage_keys.dart';

class AuthController extends GetxController {
  var registerLoading = false.obs;
  var loginLoading = false.obs;
  var logoutLoading = false.obs;

  Future<void> register(String name, String email, String password) async {
    try {
      registerLoading.value = true;
      final AuthResponse data = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {"name ": name},
      );
      registerLoading.value = false;

      if (data.user != null) {
        StorageService.session.write(
          StorageKeys.userSession,
          data.session!.toJson(),
        );
        Get.offAllNamed(RouteNamess.home);
      }
    } on AuthException catch (e) {
      registerLoading.value = false;

      showSnackBar("Registration Failed", e.message);
    }
  }

  // Login User
  Future<void> login( String email, String password) async {
    try {
      loginLoading.value = true;

      final AuthResponse res = await SupabaseService.client.auth
          .signInWithPassword(email: email, password: password);
      loginLoading.value = false;

      if (res.user != null) {
        StorageService.session.write(
          StorageKeys.userSession,
          res.session!.toJson(),
        );
        Get.offAllNamed(RouteNamess.home);
      }
    } on AuthException catch (e) {
      loginLoading.value = false;

      showSnackBar("Login Failed", e.message);
    }


  }
      Future<void> logout() async {
      try {
        logoutLoading.value = true;
        await SupabaseService.client.auth.signOut();
        logoutLoading.value = false;
        await StorageService.session.erase(); 
        Get.offAllNamed(RouteNamess.login); 
        showSnackBar("Logged Out", "You have been signed out successfully.");
      } catch (e) {
        showSnackBar("Logout Failed", "Please try again.");
      }
    }
}
















































