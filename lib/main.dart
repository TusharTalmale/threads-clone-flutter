import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Your app-specific imports
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/Services/storage_service.dart';
import 'package:thread_app/controller/auth_controller.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/controller/notification_controller.dart';
import 'package:thread_app/firebase_options.dart';
import 'package:thread_app/theme/themedata.dart';
import 'package:thread_app/Route/route.dart';

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize storage
  await GetStorage.init();
}

void main() async {
  // Wrap in error boundary
  runZonedGuarded(() async {
    await _initializeApp();
    
    // Initialize controllers after all services are ready
    Get.put(AuthController(), permanent: true);
    Get.put(NotificationController(), permanent: true);
    // Get.put(HomeController(), permanent: true);
    
    // Run app with DevicePreview in debug mode
    // runApp(
    //   kReleaseMode 
    //     ? const MyApp()
    //     : DevicePreview(
    //         enabled: true,
    //         builder: (context) => const MyApp(),
    //       ),
    // );
     runApp(MyApp());
  }, (error, stack) {
    debugPrint("Uncaught error: $error");
    debugPrint(stack.toString());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a separate widget for the main app to reduce build() complexity
    return _AppContent();
  }
}

class _AppContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      
      // DevicePreview configuration
      // useInheritedMediaQuery: !kReleaseMode,
      // locale: !kReleaseMode ? DevicePreview.locale(context) : null,
      // builder: !kReleaseMode ? DevicePreview.appBuilder : null,
      
      theme: theme, 
      darkTheme: ThemeData.dark(), 
      initialRoute: StorageService.getUserSession() != null
          ? RouteNamess.home 
          : RouteNamess.login,
      getPages: Routess.pages, 
      defaultTransition: Transition.noTransition,
    );
  }
}