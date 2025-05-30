import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Services/storage_service.dart';
import 'package:thread_app/controller/profile_controller.dart';
import 'package:thread_app/widgets/image_circle.dart';
import 'package:thread_app/controller/auth_controller.dart'; // Import AuthController

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final ProfileController profileController = Get.find<ProfileController>();
  final AuthController authController = Get.find<AuthController>(); // Get AuthController instance
  final TextEditingController descController = TextEditingController(text: "");

  // State to hold the current avatar URL
  String? _currentAvatarUrl;
  bool _isLoadingProfile = true; 

  @override
  void initState() {
    super.initState();
    debugPrint( profileController.userDescription.value);
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoadingProfile = true;
    });

    try {
      final String? userId = StorageService.userSession?['uid'];

      if (userId != null) {
       
        final Map<String, dynamic>? userProfile =
            await profileController.getUserProfile(userId); 

        if (userProfile != null) {
          descController.text = userProfile['description'] ?? ''; 
          _currentAvatarUrl = userProfile['avatar_url']; 
        }
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
     
    } finally {
      // Set loading state to false
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  @override
  void dispose() {
    descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(), 
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          Obx(
            () => TextButton(
              onPressed: profileController.saveloading.value
                  ? null // Disable button while saving
                  : () {
                      profileController.updateProfile(descController.text);
                    },
              child: profileController.saveloading.value
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.black26,
                        color: Color.fromARGB(255, 253, 255, 253), 
                      ),
                    )
                  : const Text(
                      "Save",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16, // Adjusted font size for readability
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Obx(() {
              return Stack(
                alignment: Alignment.bottomRight,
                children: [
                  profileController.loading.value == true
                      ? Column(
                          children: const [
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: Colors.grey,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.blue,
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text("Loading... Please wait"),
                          ],
                        )
                      : CircleImage(
                          radius: 80,
                          file: profileController.image.value, 
                          url: _currentAvatarUrl, 
                        ),
                  IconButton(
                    onPressed: () {
                      profileController.pickImage();
                    },
                    icon: const CircleAvatar(
                      backgroundColor: Colors.white70,
                      child: Icon(Icons.edit),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 20),
            TextFormField(
              controller: descController,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                hintText: "Your Description",
                label: Text("Description"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}