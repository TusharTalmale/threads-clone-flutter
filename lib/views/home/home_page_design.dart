import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/home_controller.dart';
import 'package:thread_app/views/home/threads_card.dart';

class HomePageDesign extends StatelessWidget {
  HomePageDesign({super.key});
  final HomeController _homeController = Get.find<HomeController>();  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: CustomScrollView(
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
            ),
            // SliverToBoxAdapter(
            //   child: Obx(() {
            //     if (_homeController.isLoading.value) {
            //       return const Center(child: CircularProgressIndicator());
            //     } else if (_homeController.threads.isEmpty) {
            //       return const Center(child: Text('No threads to display.'));
            //     } else {
            //       return ListView.builder(
            //         shrinkWrap: true,
            //         padding: EdgeInsets.zero,
            //         physics: const BouncingScrollPhysics(),
            //         itemCount: _homeController.threads.length,
            //         // scrollDirection: Axis.horizontal,
            //         itemBuilder:
            //             (context, index) =>
            //                 ThreadsCard(post: _homeController.threads[index]),
            //       );
            //     }
            //   }),
            // ),
            SliverToBoxAdapter(
              child: Obx(() {
                if (_homeController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                } else if (_homeController.threads.isEmpty) {
                  return const Center(child: Text('No threads to display.'));
                } else {
                  return ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _homeController.threads.length,
                    itemBuilder: (context, index) {
                      final thread = _homeController.threads[index];
                      return ThreadsCard(post: thread);
                    },
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}
