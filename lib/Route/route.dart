import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/views/auth/login.dart';
import 'package:thread_app/views/auth/register.dart';
import 'package:thread_app/views/home.dart';
import 'package:thread_app/views/profile/edit_profile.dart';

class Routess {
  static final pages = [
    GetPage(name: RouteNamess.home, page: () => Home()),
    GetPage(
      name: RouteNamess.login,
      page: () => const Login(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: RouteNamess.register,
      page: () => const Register(),
      transition: Transition.fade,
    ),
     GetPage(
      name: RouteNamess.editProfile,
      page: () => const EditProfile(),
      transition: Transition.leftToRightWithFade,
    ),
    


  ];
}
