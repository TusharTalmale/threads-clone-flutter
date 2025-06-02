import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id; // Notification document ID
  final String recipientId; // The user ID who receives the notification
  final String senderId; // The user ID who triggered the notification (e.g., liker, commenter)
  final String type; // 'like', 'comment', 'follow', 'report'
  final String? threadId; // ID of the thread if applicable (for likes/comments/reports)
  final String? replyId; // ID of the reply if applicable (for comments)
  final String message; // A custom message for the notification
  final String? imageUrl; // Optional: URL of an image associated with the notification (e.g., sender's avatar, thread image)
  final Timestamp timestamp;
  final bool read; // Whether the user has viewed this notification

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.type,
    this.threadId,
    this.replyId,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    this.read = false, // Default to unread
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      type: data['type'] ?? '',
      threadId: data['threadId'],
      replyId: data['replyId'],
      message: data['message'] ?? 'New notification',
      imageUrl: data['imageUrl'],
      timestamp: data['timestamp'] as Timestamp,
      read: data['read'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'senderId': senderId,
      'type': type,
      'threadId': threadId,
      'replyId': replyId,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'read': read,
    };
  }

  // Helper for reactive updates
  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    String? type,
    String? threadId,
    String? replyId,
    String? message,
    String? imageUrl,
    Timestamp? timestamp,
    bool? read,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      threadId: threadId ?? this.threadId,
      replyId: replyId ?? this.replyId,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
    );
  }
}