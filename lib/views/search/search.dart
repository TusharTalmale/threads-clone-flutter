import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'dart:async'; // Required for Timer

import 'package:thread_app/controller/search_controller.dart';
import 'package:thread_app/views/profile/user_profile_page.dart';

import 'package:thread_app/views/search/search_input.dart';
import 'package:thread_app/widgets/image_circle.dart';
// Ensure these imports are correct for your project structure



class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final SearchedController searchController = Get.put(SearchedController());
  final TextEditingController textEditingController = TextEditingController(text: '');

  Timer? _debounce; 

  @override
  void initState() {
    super.initState();
    textEditingController.addListener(() {
      final query = textEditingController.text;
      if (query.isEmpty) {
        searchController.searchedUsers.clear();
        searchController.searchedThreads.clear();
        _debounce?.cancel(); 
      } else {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          searchController.performSearch(query);
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); 
    textEditingController.dispose();
    super.dispose();
  }

  void _onSearch(String? query) {
    if (query == null || query.isEmpty) {
      searchController.searchedUsers.clear();
      searchController.searchedThreads.clear();
    }
  
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            centerTitle: false,
            title: const Text(
              'Search',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            expandedHeight: GetPlatform.isIOS ? 110 : 105,
            collapsedHeight: GetPlatform.isIOS ? 90 : 80,
            flexibleSpace: Padding(
              padding: EdgeInsets.only(top: GetPlatform.isIOS ? 105 : 100, left: 10, right: 10),
              child: SearchInput(
                controller: textEditingController,
                callback: _onSearch, 
              ),
            ),
          ),
          Obx(() {
            if (searchController.isSearching.value) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (searchController.searchError.value.isNotEmpty) {
              return SliverFillRemaining(
                child: Center(child: Text(searchController.searchError.value)),
              );
            } else if (textEditingController.text.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Start typing to search for users or posts.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            } else {
              if (searchController.searchedUsers.value.isEmpty && searchController.searchedThreads.value.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No results found.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                );
              }
              return _buildSearchResults();
            }
          }),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return SliverList(
      delegate: SliverChildListDelegate(
        [
          if (searchController.searchedUsers.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Users',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchController.searchedUsers.value.length, 
            itemBuilder: (context, index) {
              final user = searchController.searchedUsers.value[index];
              return ListTile(
                leading: CircleImage( url: user.avatar_url,  ),
                title: Text(user.name),
                subtitle: Text(user.email),
                onTap: () {
                  Get.toNamed(RouteNamess.showUserprofile , arguments: user.userId);
                },
              );
            },
          ),
       
          if (searchController.searchedThreads.value.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Threads',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: searchController.searchedThreads.value.length, // CORRECT: Accessing .value for length
            itemBuilder: (context, index) {
              final thread = searchController.searchedThreads.value[index]; // CORRECT: Accessing .value for element
              return ListTile(
                leading: thread.imageUrls.isNotEmpty
                    ? Image.network(
                        thread.imageUrls.first,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported, size: 50), 
                      )
                    : const Icon(Icons.text_fields, size: 50), 
                title: Text(thread.content.length > 50
                    ? '${thread.content.substring(0, 50)}...'
                    : thread.content),
                subtitle: Text('Replies: ${thread.repliesCount}'),
                onTap: () {
                  // Get.to(() => ThreadDetailView(threadId: thread.threadId));
                    Get.toNamed(RouteNamess.comments, arguments: thread.threadId);

                },
              );
            },
          ),
        ],
      ),
    );
  }
}