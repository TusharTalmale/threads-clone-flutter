import 'package:flutter/material.dart';

class AddThread extends StatelessWidget {
  const AddThread({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
