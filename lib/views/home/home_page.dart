import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/auth_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController nameController = TextEditingController();
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        actions: [
          Obx(
            () => IconButton(
              icon:
                  authController.logoutLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.logout),
              onPressed:
                  authController.logoutLoading.value
                      ? null
                      : () async {
                        await authController.logout();
                      },
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome to the Home Screen!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await authController.logout();
              },
              child: Obx(
                () =>
                    authController.logoutLoading.value
                        ? const CircularProgressIndicator()
                        : const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
