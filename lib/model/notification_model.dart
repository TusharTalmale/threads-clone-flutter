import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id; // Notification document ID
  final String recipientId; // The user ID who receives the notification
  final String senderId;  
  final String senderName;
  final String type; 
  final String? threadId; 
  final String? replyId;
  final String message;
  final String? imageUrl; 
  final Timestamp timestamp;
  final bool read; 

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.senderId,
    required this.senderName,
    required this.type,
    this.threadId,
    this.replyId,
    required this.message,
    this.imageUrl,
    required this.timestamp,
    this.read = false, 
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
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
      'senderName':senderName,
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
    String? senderName,
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
      senderName: senderName ?? this.senderName,
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