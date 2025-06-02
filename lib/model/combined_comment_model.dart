
import 'package:thread_app/model/comment_model.dart';
import 'package:thread_app/model/user_model.dart';

class CombinedCommentModel {
  final CommentModel comment;
  final UserModel user;

  CombinedCommentModel({required this.comment, required this.user});
}