import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/views/home/home_page.dart';
import 'package:thread_app/views/home/home_page_design.dart';
import 'package:thread_app/views/profile/profile.dart';
import 'package:thread_app/views/search/search.dart';
import 'package:thread_app/views/threads/thread.dart';
import 'package:thread_app/views/notification/notification.dart';

class NavigationService extends GetxService {
  var currentIndex = 0.obs;
  var previousIndex = 0.obs;

  // all pages
  List<Widget> pages(){
    return [
      //  HomePage(),
      HomePageDesign(),
      const Search(),
       AddThread(),
       NotificationsScreen(),
      const Profile(),
    ];
  }
// update index
void updateIndex(int index){
  previousIndex.value = currentIndex.value;
  currentIndex.value = index;
}
//back to prev page
void backToPrevPage(){
  currentIndex.value = previousIndex.value;
}

  
}