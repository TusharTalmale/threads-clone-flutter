import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/widgets/image_circle.dart'; // Assuming you have this

class HomePage extends StatelessWidget {
  HomePage({super.key});

  // Initialize HomeController
  final HomeController homeController = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Threads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => homeController.fetchThreads(), 
          ),
        ],
      ),
      body: Obx(() {
        if (homeController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (homeController.threads.isEmpty) {
          return const Center(child: Text('No threads to display.'));
        } else {
          return ListView.builder(
            itemCount: homeController.threads.length,
            itemBuilder: (context, index) {
              final post = homeController.threads[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Info Row
                      Row(
                        children: [
                          // Use the corrected avatar_url field
                          CircleImage(radius: 20, url: post.user.avatar_url ?? ''),
                          const SizedBox(width: 10),
                          Text(
                            post.user.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '@${post.user.email.split('@')[0]}', // Display username from email
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Thread Content
                      Text(post.thread.content),
                      if (post.thread.imageUrls.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: post.thread.imageUrls.map((url) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  url,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image), // Fallback
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      if (post.thread.videoUrl != null && post.thread.videoUrl!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Container(
                            width: 200,
                            height: 150,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      // Likes and Replies (You can add interactive buttons here)
                      Row(
                        children: [
                          Icon(Icons.favorite_border, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${post.thread.likesCount}'),
                          const SizedBox(width: 15),
                          Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text('${post.thread.repliesCount}'),
                          const Spacer(),
                          Text(
                            '${post.thread.createdAt.toLocal().hour}:${post.thread.createdAt.toLocal().minute}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
        
          Get.toNamed('/addThread');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
