import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/utils/replies/add_reply.dart';
import 'package:thread_app/views/auth/login.dart';
import 'package:thread_app/views/auth/register.dart';
import 'package:thread_app/views/home.dart';
import 'package:thread_app/views/home/comment_page_ui.dart';
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

     GetPage(
      name: RouteNamess.addReply,
      page: () =>  ReplyPage(),
      transition: Transition.downToUp,
    ),
    
   GetPage(
      name: RouteNamess.comments,
      page: () =>  CommentPage(),
      transition: Transition.downToUp,
    ),

  ];
}
