import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/Services/storage_service.dart';
import 'package:thread_app/Services/supabase_service.dart';
import 'package:thread_app/theme/themedata.dart';
import 'package:thread_app/Route/route.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized;
  await dotenv.load(fileName: ".env");
  await GetStorage.init();
  Get.put(SupabaseService());
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MyApp(), // Wrap your app
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: theme,
      darkTheme: ThemeData.dark(),
      initialRoute: StorageService.userSession != null
          ? RouteNamess.home 
          : RouteNamess.login,
      getPages: Routess.pages ,
      defaultTransition: Transition.noTransition,
    );
  }
}
