import 'package:flutter/material.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationStates();
}

class _NotificationStates extends State<Notifications> {
  @override
  Widget build(BuildContext context) {
    return   Scaffold(
      appBar: AppBar(
        title: const Text("Notification"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_add),
            onPressed: () {
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to the Notification Page!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
