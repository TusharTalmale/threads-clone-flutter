// --- Sidebar Content Widget (renamed for clarity) ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/auth_controller.dart';
import 'package:thread_app/widgets/conform_dilog.dart';

Widget buildRightSidebarContent(BuildContext context) {
  // Access the AuthController here. It should be initialized globally (e.g., in main.dart).
  final AuthController authController = Get.find<AuthController>();

  return Material(
    color:
        Theme.of(context).scaffoldBackgroundColor, // Use theme background color
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(15),
      bottomLeft: Radius.circular(15),
    ), // Optional: rounded corners
    child: SizedBox(
      width: 200, // Fixed width for the sidebar
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(15, 40, 10, 50),
            child: Text(
              "Settings",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.white),
            title: const Text(
              "Settings",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(
                context,
              ); // Close sidebar before navigating or performing action
              Get.toNamed(
                RouteNamess.settingPage,
              ); // Navigate to your setting page
            },
          ),
          // --- LOGOUT BUTTON ---
          // Use Obx to reactively update the button state (loading/enabled)
          Obx(
            () => ListTile(
              leading:
                  authController.logoutLoading.value
                      ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.logout, color: Colors.white),
              title:
                  authController.logoutLoading.value
                      ? const Text(
                        'Logging Out...',
                        style: TextStyle(color: Colors.white),
                      )
                      : const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
              onTap:
                  authController.logoutLoading.value
                      ? null
                      : () {
                        // Show the custom dialog before logging out
                        Get.dialog(
                          const LogoutConfirmationDialog(title: 'Confirm Logout?', subtitle: "You will be signed out and redirected to the Login page.", icon:  Icons.logout,

                          ),
                          barrierDismissible:
                              false, // Prevent dismissing by tapping outside
                        );
                      },
            ),
          ),
          // Add more list items as needed
        ],
      ),
    ),
  );
}
