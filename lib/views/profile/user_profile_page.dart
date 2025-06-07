import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/profile/user_profile_controller.dart';
import 'package:thread_app/widgets/image_circle.dart';
import 'package:thread_app/views/home/threads_card.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShowProfile extends StatefulWidget {
  const ShowProfile({super.key});

  @override
  State<ShowProfile> createState() => _ShowProfileState();
}

class _ShowProfileState extends State<ShowProfile> {
  final String userId = 'g8PeA8nHjIcOL3O3FTafYp18A6c2';

  late final UserProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(UserProfileController(targetUserId: userId), tag: userId);
  }

  @override
  void dispose() {
    // Clean up the controller when the page is disposed
    Get.delete<UserProfileController>(tag: userId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? currentLoggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
    
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger a refresh of all data streams in the controller
          await controller.refreshProfileAndThreads();
        },
        child: CustomScrollView( 
          slivers: [
            // --- Profile Header (SliverAppBar with FlexibleSpaceBar) ---
            SliverAppBar(
            
              expandedHeight: 140, 
              floating: false,
              pinned: true, 
              stretch: true, // Allows content to stretch when over-scrolling
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16.0),
                background: Obx(
                  () {
                    if (controller.userLoading.value) {
                      return const Center(child: CircularProgressIndicator()); // Your custom loading widget
                    }

                    // Profile content
                    final userProfile = controller.user.value;
                    if (userProfile == null) {
                      return Center(
                        child: Text(
                          controller.errorMessage.value.isNotEmpty
                              ? controller.errorMessage.value
                              : 'User profile not found.',
                          style: const TextStyle(fontSize: 16, color: Colors.white), // Text color for visibility on blue background
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end, 
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userProfile.name, // Direct access to name
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                      color: Colors.white, // Text color for visibility
                                    ),
                                  ),
                                  SizedBox(
                                    width: context.width * 0.60,
                                    child: Text(
                                      userProfile.description ?? 'No description provided.', // Direct access to description
                                      style: const TextStyle(fontSize: 14, color: Colors.white70), // Text color for visibility
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ],
                              ),
                              CircleImage(
                                url: userProfile.avatar_url, // Direct access to avatar_url
                                radius: 40,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Edit Profile Button (only visible if it's the current user's profile)
                          if (currentLoggedInUserId == userId)
                            Align(
                              alignment: Alignment.centerLeft, // Align left within its column
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Get.snackbar('Edit Profile', 'Implement navigation to your Edit Profile screen.',
                                    snackPosition: SnackPosition.BOTTOM);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white, // Button background
                                  foregroundColor: Colors.blue.shade700, // Text/icon color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Obx(
                  () {
                    // Show loading indicator for user's threads
                    if (controller.postLoading.value) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (controller.posts.isEmpty) {
                      return const Center(
                        child: Text("No Post found"),
                      );
                    } else if (controller.errorMessage.isNotEmpty) {
                      return Center(
                        child: Text(
                          'Error loading posts: ${controller.errorMessage.value}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), 
                        itemCount: controller.posts.length,
                        itemBuilder: (context, index) =>
                            ThreadsCard(
                              post: controller.posts[index],
                            ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
