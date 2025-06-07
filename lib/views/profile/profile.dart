import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/profile_controller.dart';
import 'package:thread_app/controller/reply_controller.dart';
import 'package:thread_app/utils/styles/button_style.dart';
import 'package:thread_app/views/profile/sidebar.dart';
import 'package:thread_app/views/profile/threads_profile_view.dart';
import 'package:thread_app/widgets/image_circle.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileController profileController = Get.put(ProfileController());
  final CommentController commentController = Get.put(CommentController());

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await profileController.fetchUserProfileData();
    if (FirebaseAuth.instance.currentUser?.uid != null) {
      commentController.fetchCurrentUserReplies();
      commentController.fetchRepliesOnMyPosts();
    }
  }

  void _showRightSidebar() {
    showGeneralDialog(
      context: context,
      barrierLabel: "Sidebar",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: buildRightSidebarContent(context),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedValue = Curves.easeInOut.transform(animation.value);
        return Transform.translate(
          offset: Offset(
            MediaQuery.of(context).size.width * (1 - curvedValue),
            0,
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildRepliesTab() {
    return Obx(() {
      if (commentController.isLoadingCurrentUserReplies.value || 
          commentController.isLoadingRepliesOnMyPosts.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: "Your Replies"),
                Tab(text: "Replies to You"),
              ],
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Your Replies Tab
                  ListView.builder(
                    itemCount: commentController.currentUserReplies.length,
                    itemBuilder: (context, index) {
                      final reply = commentController.currentUserReplies[index];
                      return ListTile(
                        leading: CircleImage(
                          radius: 20,
                          url: reply.user.avatar_url,
                        ),
                        title: Text(reply.comment.content),
                        subtitle: Text(
                          'Replying to ${reply.comment.threadId}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                  
                  // Replies to You Tab
                  ListView.builder(
                    itemCount: commentController.repliesOnMyPosts.length,
                    itemBuilder: (context, index) {
                      final reply = commentController.repliesOnMyPosts[index];
                      return ListTile(
                        leading: CircleImage(
                          radius: 20,
                          url: reply.user.avatar_url,
                        ),
                        title: Text(reply.user.name),
                        subtitle: Text(
                          reply.comment.content,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.language),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showRightSidebar,
          ),
        ],
      ),
      body: Obx(() {
        if (profileController.profileLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        return DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return <Widget>[
                SliverAppBar(
                  expandedHeight: 180,
                  collapsedHeight: 160,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                onPressed: () {},
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
                SliverPersistentHeader(
                  floating: true,
                  pinned: true,
                  delegate: SliverAppBarDelegate(
                    const TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey,
                      tabs: [Tab(text: "Threads"), Tab(text: "Replies")],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                ProfileThreadsView(
                  viewingUserId: FirebaseAuth.instance.currentUser?.uid,
                ),
                _buildRepliesTab(),
              ],
            ),
          ),
        );
      }),
    );
  }
}

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