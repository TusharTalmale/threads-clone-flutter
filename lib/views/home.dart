import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Services/navigation_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:thread_app/views/notification/notification_badge.dart';

class Home extends StatelessWidget {
  Home({super.key});
  final NavigationService navigationService = Get.put(NavigationService());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationService.currentIndex.value,
onDestinationSelected: (value) => navigationService.updateIndex(value),
                   animationDuration: Duration(microseconds: 500),

          destinations: const <Widget>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: "Home",
              selectedIcon: Icon(Icons.home),
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              label: "Search",
              selectedIcon: Icon(Icons.search),
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.add_circled),
              label: "Add Thread",
              selectedIcon: Icon(CupertinoIcons.add_circled_solid),
            ),
            NavigationDestination(
              icon: NotificationBadge(),
              label: "Notification",
              selectedIcon: Icon(Icons.favorite),
            
            ),
            NavigationDestination(
              icon: Icon(Icons.person_2_outlined),
              label: "Profile",
              selectedIcon: Icon(Icons.person_2),
            ),
          ],
        ),

        body: AnimatedSwitcher(
          duration:const Duration(microseconds : 500),
          switchInCurve: Curves.bounceIn,
          switchOutCurve: Curves.bounceInOut,
          child: navigationService.pages()[navigationService.currentIndex.value],
          ) ,

      ),
    );
  }
}
