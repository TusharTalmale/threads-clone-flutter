import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:thread_app/model/threads_model.dart';
import 'package:thread_app/model/user_model.dart';
import 'package:thread_app/utils/helper.dart'; // For showCustomSnackBar

class SearchedController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RxList<UserModel> searchedUsers = <UserModel>[].obs;
  final RxList<ThreadModel> searchedThreads = <ThreadModel>[].obs;
  final RxBool isSearching = false.obs;
  final RxString searchError = ''.obs;

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      searchedUsers.clear(); 
      searchedThreads.clear(); 
      isSearching.value = false; 
      return;
    }

    isSearching.value = true; 
    searchError.value = '';    
    searchedUsers.clear();    
    searchedThreads.clear();   

    try {
      // 1. Search Users by Name
      final userQueryLowerCase = query.toLowerCase();
      final userSnapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: userQueryLowerCase)
          .where('name', isLessThan: userQueryLowerCase + '\uf8ff')
          .limit(10)
          .get();

      for (var doc in userSnapshot.docs) {
        searchedUsers.add(UserModel.fromFirestore(doc));
      }

      // 2. Search Threads by Content (Client-side filtering - NOT SCALABLE)
      // Reminder: For production, use Algolia/Elasticsearch for full-text search.
      final threadSnapshot = await _firestore
          .collection('threads')
          .limit(50) // Fetch a limited number of threads
          .get();

      for (var doc in threadSnapshot.docs) {
        final thread = ThreadModel.fromFirestore(doc);
        if (thread.content.toLowerCase().contains(query.toLowerCase())) {
          searchedThreads.add(thread);
        }
      }

    } on FirebaseException catch (e) {
      searchError.value = 'Firebase Error: ${e.message}'; 
      showCustomSnackBar(
        title: 'Search Error',
        message: 'Failed to perform search: ${e.message}',
        isError: true,
      );
    } catch (e) {
      searchError.value = 'An unexpected error occurred: $e'; 
      showCustomSnackBar(
        title: 'Search Error',
        message: 'An unexpected error occurred: $e',
        isError: true,
      );
    } finally {
      isSearching.value = false;
    }
  }
}