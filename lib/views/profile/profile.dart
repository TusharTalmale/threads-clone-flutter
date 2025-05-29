import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_utils/src/extensions/context_extensions.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/profile_controller.dart';
import 'package:thread_app/utils/styles/button_style.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final ProfileController controller = Get.put(ProfileController());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Icon(Icons.language),
        centerTitle: false,

        actions: [IconButton(icon: const Icon(Icons.sort), onPressed: () {})],
      ),
      body: DefaultTabController(
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
                  child:  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tushar ",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: context.width * 0.60,
                                child:const  Text(
                                  "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                                ),
                              ),
                            ],
                          ),
                          const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(
                              'assets/images/avatar.png',
                            ),
                          ),
                         
                        ],
                      ),

                     const  SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Get.toNamed(RouteNamess.editProfile),
                              style: customOutlinestyle(),
                              child: const Text("Edit Profile",
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: customOutlinestyle(),
                              child: const Text("Shared Profile",                               style: TextStyle(color: Colors.white),
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
                    tabs: [Tab(text: "Threads",), Tab(text: "Replies")],
                    
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [Text("Threads "), Text("Replies broooooooo ")],
          ),
        ),
      ),
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
    return Container(color: Colors.black, child: _tabBar);
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
