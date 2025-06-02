import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String commentId;
  final String threadId; // ID of the thread this comment belongs to
  final String userId; // ID of the user who posted this comment
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt; // NEW: Mark as nullable

  CommentModel({
    required this.commentId,
    required this.threadId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt, // NEW: Include in constructor
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      commentId: doc.id,
      threadId: data['threadId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(), // Handle potential null for old data
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(), // NEW: Handle nullable
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null, // NEW: Store nullable
    };
  }
}