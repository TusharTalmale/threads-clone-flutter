import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/auth_controller.dart'; // Ensure this path is correct
import 'package:thread_app/controller/profile_controller.dart'; // Ensure this path is correct
import 'package:thread_app/utils/styles/button_style.dart'; // Ensure this path is correct
import 'package:thread_app/views/profile/sidebar.dart';
import 'package:thread_app/widgets/image_circle.dart'; // Ensure this path is correct

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  
  final ProfileController profileController = Get.put(ProfileController());


  @override
  void initState() {
    super.initState();
    profileController.fetchUserProfileData();
  }

  // --- Function to show the Right Sidebar ---
  void _showRightSidebar() {
    showGeneralDialog(
      context: context,
      barrierLabel: "Sidebar",
      barrierDismissible: true, // Dismiss when tapping outside
      barrierColor: Colors.black.withOpacity(0.5), // Dim background
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
       
        return Align(
          alignment: Alignment.centerRight,
          child: buildRightSidebarContent(context), // Call the helper function for content
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // Slide animation from right
        final curvedValue = Curves.easeInOut.transform(animation.value);
        return Transform.translate(
          offset: Offset(
            MediaQuery.of(context).size.width * (1 - curvedValue),
            0,
          ),
          child: child, // The child here is the result of pageBuilder
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.language), // Placeholder icon
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showRightSidebar();
            },
          ),
        ],
      ),
      body: Obx(() {
        if (profileController.profileLoading.value) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        // Once data is loaded, display the profile content
        return DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: 180, // Height when fully expanded
                  collapsedHeight: 160,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        // User Name, Description, and Avatar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Display User Name from controller
                                Text(
                                  profileController.userName.value,
                                  style: const TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),

                                SizedBox(
                                  width: context.width * 0.60,
                                  child: Text(
                                    profileController.userDescription.value,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.8),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            CircleImage(
                              radius: 40,
                              url: profileController.userAvatarUrl.value,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Action Buttons (Edit Profile, Shared Profile)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Get.toNamed(RouteNamess.editProfile)?.then((_) {
                                    profileController.fetchUserProfileData();
                                  });
                                },
                                style: customOutlinestyle(),
                                child: const Text("Edit Profile"),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Add share profile logic here
                                },
                                style: customOutlinestyle(),
                                child: const Text(
                                  "Shared Profile",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab Bar for "Threads" and "Replies"
                SliverPersistentHeader(
                  floating: true,
                  pinned: true,
                  delegate: SliverAppBarDelegate(
                    const TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Colors.white, // Color of the selected tab indicator
                      labelColor: Colors.white, // Color of selected tab text
                      unselectedLabelColor: Color.fromARGB(255, 189, 12, 12),
                      tabs: [Tab(text: "Threads"), Tab(text: "Replies")],
                    ),
                  ),
                ),
              ];
            },
            // Content for the tabs
            body: const TabBarView(
              children: [
                Center(child: Text("Threads content goes here")),
                Center(child: Text("Replies content goes here")),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for the TabBar (no changes needed here)
class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  SliverAppBarDelegate(this._tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
