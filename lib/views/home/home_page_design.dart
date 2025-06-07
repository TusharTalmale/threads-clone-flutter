import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/views/home/threads_card.dart';

class HomePageDesign extends StatelessWidget {
  final HomeController _homeController = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0), 
              child: Center(
                child: SizedBox(
                  height: 40,
                  width: 40,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white // White logo in dark mode
                          : Colors.black, // Black logo in light mode
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/images/logos.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Expanded( 
              child: Obx(() {
                return RefreshIndicator(
                  onRefresh: _homeController.refreshThreads,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                     
                      SliverAppBar(
                        centerTitle: true,
                        title: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Image.asset(
                            "assets/images/logos.png",
                            width: 40,
                            height: 40,
                          ),
                        ),
                        floating: true,
                        pinned: false, 
                        backgroundColor: Colors.transparent, 
                      ),
                      _buildThreadsList(),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreadsList() {
    if (_homeController.isLoading.value && _homeController.threads.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_homeController.threads.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum, size: 50, color: Colors.grey),
              SizedBox(height: 16),
              Text('No threads to display'),
              TextButton(
                onPressed: _homeController.refreshThreads,
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final thread = _homeController.threads[index];
          return ThreadsCard(post: thread);
        },
        childCount: _homeController.threads.length,
      ),
    );
  }
}