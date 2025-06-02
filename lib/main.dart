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


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  Get.put(AuthController());
  Get.put(NotificationController());
Get.put(HomeController());


  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Enable Device Preview only in non-release modes
      builder: (context) => const MyApp(), // Your app widget
    ),
  );
  //  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {


    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      useInheritedMediaQuery: true, // Required for DevicePreview
      locale: DevicePreview.locale(context), // Required for DevicePreview
      builder: DevicePreview.appBuilder, // Required for DevicePreview

      theme: theme, 
      darkTheme: ThemeData.dark(), 
      initialRoute: 
               StorageService.getUserSession() != null
          ? RouteNamess.home 
          : RouteNamess.login,
      getPages: Routess.pages, 
      defaultTransition:
          Transition.noTransition, 
    );
  }
}
