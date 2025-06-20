import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:thread_app/model/notification_model.dart';

class NotificationController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  final RxInt unreadCount = 0.obs;
  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      _setupUnreadCounter();
    }
  }

  void _setupUnreadCounter() {
    _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          unreadCount.value = snapshot.size;
        });
  }

  // Send a notification
  Future<void> sendNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String type,
    String? threadId,
    String? replyId,
    String? imageUrl,
  }) async {
    if (recipientId == senderId) return;

    final message = _generateMessage(type, senderName);

    await _firestore.collection('notifications').add({
      'recipientId': recipientId,
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'threadId': threadId,
      'replyId': replyId,
      'message': message,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  String _generateMessage(String type, String userName) {

    switch (type) {
      case 'like':
        return '$userName liked your post';
      case 'comment':
        return '$userName commented on your post';
      case 'follow':
        return '$userName started following you';
      case 'report':
        return 'Your post was reported  by $userName ';
      default:
        return 'New notification';
    }
  }





  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  Future<void> markAllAsRead() async {
    final query =
        await _firestore
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserId)
            .where('read', isEqualTo: false)
            .get();

    final batch = _firestore.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => NotificationModel.fromFirestore(doc))
                  .toList(),
        );
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    if (currentUserId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }
}
