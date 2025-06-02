import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:thread_app/model/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: notification.imageUrl != null
            ? NetworkImage(notification.imageUrl!)
            : null,
        child: notification.imageUrl == null
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(notification.message),
      subtitle: Text(
        _formatTimestamp(notification.timestamp),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: !notification.read
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')} · ${date.day}/${date.month}/${date.year}';
  }
}