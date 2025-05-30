
// --- Sidebar Content Widget (renamed for clarity) ---
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/Route/route_namess.dart';
import 'package:thread_app/controller/auth_controller.dart';

Widget buildRightSidebarContent(BuildContext context) {
  // Access the AuthController here. It should be initialized globally (e.g., in main.dart).
  final AuthController authController = Get.find<AuthController>();

  return Material(
    color: Theme.of(context).scaffoldBackgroundColor, // Use theme background color
    borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)), // Optional: rounded corners
    child: SizedBox(
      width: 200, // Fixed width for the sidebar
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(15,40,10,50),
            child: Text(
              "Settings",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
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
              Navigator.pop(context); // Close sidebar before navigating or performing action
              Get.toNamed(RouteNamess.settingPage); // Navigate to your setting page
            },
          ),
          // --- LOGOUT BUTTON ---
          // Use Obx to reactively update the button state (loading/enabled)
          Obx(() =>
            ListTile(
              leading: authController.logoutLoading.value
                  ? const SizedBox( // Use a SizedBox to control the size of the progress indicator
                      width: 24, // Match icon size
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2, // Make it thinner
                      ),
                    )
                  : const Icon(Icons.logout, color: Colors.white), // Change color to white for visibility
              title: authController.logoutLoading.value
                  ? const Text("Logging Out...", style: TextStyle(color: Colors.white))
                  : const Text("Logout", style: TextStyle(color: Colors.white)),
              onTap: authController.logoutLoading.value
                  ? null // Disable tap when loading
                  : () {
                      authController.logout(); // Call the logout method from AuthController
                      // Navigator.pop(context); // You might want to close the sidebar here if it doesn't automatically close
                                                // after navigation (Get.offAllNamed)
                    },
            ),
          ),
          // Add more list items as needed
        ],
      ),
    ),
  );
}
