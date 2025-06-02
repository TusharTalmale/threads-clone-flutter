import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/notification_controller.dart';
import 'package:thread_app/model/notification_model.dart';
import 'package:thread_app/views/notification/notification_tile.dart';


class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: const Text('Mark all as read'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: controller.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final notification = snapshot.data![index];
              return NotificationTile(
                notification: notification,
                onTap: () => _handleNotificationTap(notification),
              );
            },
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    final controller = Get.find<NotificationController>();
    
    // Mark as read when tapped
    if (!notification.read) {
      controller.markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'like':
      case 'comment':
        if (notification.threadId != null) {
          Get.toNamed('/thread/${notification.threadId}');
        }
        break;
      case 'follow':
        Get.toNamed('/profile/${notification.senderId}');
        break;
      case 'report':
        // Handle report notification
        break;
    }
  }
}