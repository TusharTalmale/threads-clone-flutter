import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';

class CombinedThreadPostModel {
  final ThreadModel thread;
  final UserModel user;
  final bool isLikedByCurrentUser;


  CombinedThreadPostModel({required this.thread, required this.user , this.isLikedByCurrentUser = false,});
  
  CombinedThreadPostModel copyWith({
    ThreadModel? thread,
    UserModel? user,
    bool? isLikedByCurrentUser,
  }) {
    return CombinedThreadPostModel(
      thread: thread ?? this.thread,
      user: user ?? this.user,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
    );
  }
}
