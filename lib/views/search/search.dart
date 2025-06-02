
import 'package:flutter/material.dart';
import 'package:thread_app/views/notification/notification_badge.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("Serch"),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.search),
          //   onPressed: () {
          //   },
          // ),

              NotificationBadge(),

        ],
      ),
      body: const Center(
        child: Text(
          "Welcome to the Serch Page!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
