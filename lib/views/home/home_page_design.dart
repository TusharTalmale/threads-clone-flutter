import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/views/home/threads_card.dart'; // Assuming MyThreadsCard is renamed to ThreadsCard

class HomePageDesign extends StatefulWidget {
  const HomePageDesign({super.key}); // Add const constructor

  @override
  State<HomePageDesign> createState() => _HomePageDesignState();
}

class _HomePageDesignState extends State<HomePageDesign> {
  final HomeController _homeController = Get.put(HomeController());
  final ScrollController _scrollController = ScrollController();

  @override
  void initState()  {
    super.initState();
  _homeController.setupAuthAndThreadListener();

    _scrollController.addListener(_scrollListener);

  }

 void _scrollListener() {
  if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.9 && 
      !_homeController.isLoading.value &&
      _homeController.hasMore.value) {
    _homeController.loadMore();
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App Header
            _buildAppHeader(context),

            // Main Content
            Expanded(
              child: Obx(() {
                return RefreshIndicator(
                  onRefresh: _homeController.refreshThreads,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Threads List
                      _buildThreadsList(),

                      // Loading indicator for pagination
                      if (_homeController.isLoading.value &&
                          _homeController.threads.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),

                      // End of list message
                      if (!_homeController.hasMore.value &&
                          _homeController.threads.isNotEmpty &&
                          !_homeController.isLoading.value) // Only show when not loading
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No more threads to load',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
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

  Widget _buildAppHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
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
    );
  }

  Widget _buildThreadsList() {
    if (_homeController.isLoading.value && _homeController.threads.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_homeController.threads.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.forum, size: 50, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No threads to display',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: _homeController.refreshThreads,
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    color: Theme.of(Get.context!).primaryColor,
                  ),
                ),
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
          return Column(
            children: [
              ThreadsCard(post: thread),
              if (index == _homeController.threads.length - 1)
                const SizedBox(height: 16), // Extra space at the end
            ],
          );
        },
        childCount: _homeController.threads.length,
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // Important!
    _scrollController.dispose();
    super.dispose();
  }
}