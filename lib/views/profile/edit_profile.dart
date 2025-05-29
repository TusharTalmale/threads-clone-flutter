
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/profile_controller.dart';
import 'package:thread_app/widgets/image_circle.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final ProfileController controller = Get.find<ProfileController>();
final TextEditingController textEditingController = TextEditingController(text: "");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [TextButton(onPressed: () {}, child: const Text("Save"))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Obx(() {
              return Stack(
                alignment: Alignment.bottomRight,
                children: [
                  controller.loading.value == true
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
                      : CircleImage(radius: 80, file: controller.image.value),

                  IconButton(
                    onPressed: () {
                      controller.pickImage();
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
              controller: textEditingController,
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
