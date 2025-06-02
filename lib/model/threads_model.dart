import 'package:cloud_firestore/cloud_firestore.dart'; // Required for Timestamp

class ThreadModel {
  final String threadId;
  final String userId;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
  final int likesCount;
  final int repliesCount;
  final DateTime createdAt;
  final Timestamp? updatedAt;

  ThreadModel({
    required this.threadId,
    required this.userId,
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
    this.likesCount = 0,
    this.repliesCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a ThreadModel from a Firestore DocumentSnapshot
  factory ThreadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ThreadModel(
      threadId: doc.id, // Use doc.id for the document ID
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
      likesCount: data['likesCount'] ?? 0,
      repliesCount: data['repliesCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(), 
      updatedAt: (data['updatedAt'] as Timestamp?),
    );
  }

  // Method to convert ThreadModel to a Map for Firestore (useful for posting)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'likesCount': likesCount,
      'repliesCount': repliesCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt,

    };
  }
  // Add to ThreadModel class
ThreadModel copyWith({
  String? threadId,
  String? userId,
  String? content,
  List<String>? imageUrls,
  String? videoUrl,
  int? likesCount,
  int? repliesCount,
  DateTime? createdAt,
}) {
  return ThreadModel(
    threadId: threadId ?? this.threadId,
    userId: userId ?? this.userId,
    content: content ?? this.content,
    imageUrls: imageUrls ?? this.imageUrls,
    videoUrl: videoUrl ?? this.videoUrl,
    likesCount: likesCount ?? this.likesCount,
    repliesCount: repliesCount ?? this.repliesCount,
    createdAt: createdAt ?? this.createdAt,
  );
}
}
