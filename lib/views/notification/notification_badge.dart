import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/notification_controller.dart';
import 'package:thread_app/views/notification/notification.dart';

class NotificationBadge extends StatelessWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    
    return Obx(() {
      final count = controller.unreadCount.value;
      return Stack(
        children: [
          Icon(
            (Icons.favorite_outline),
            // onPressed: () => Get.to(() => const NotificationsScreen()),
          ),

          if (count > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      );
    });
  }
}