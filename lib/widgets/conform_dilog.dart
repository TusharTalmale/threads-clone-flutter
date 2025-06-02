import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thread_app/controller/auth_controller.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  final String? title ;
  final String? subtitle ;
  final IconData? icon ;

  const LogoutConfirmationDialog({super.key
  , required this.title , required this.subtitle ,required this.icon });

  final Color primaryDarkColor = const Color.fromARGB(255, 243, 49, 52);
  final Color dialogBackgroundColor = Colors.black54;
  final Color textColor = Colors.white;
  final Color secondaryTextColor = Colors.white70;

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Dialog(
      elevation: 8, 
      backgroundColor:
          Colors
              .transparent, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: MediaQuery.of(context).size.width / 1.4,
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 15,
        ),
        decoration: BoxDecoration(
          color:
              dialogBackgroundColor, // The main dark background for the dialog
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 10),
              blurRadius: 20,
              spreadRadius: 0,
              color: Colors.white.withOpacity(
                0.05,
              ), 
            ),
          ],
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Make column only take required height
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon at the top
            CircleAvatar(
              backgroundColor: primaryDarkColor.withOpacity(
                0.1,
              ), // Subtle background for icon
              radius: 30,
              child: Icon(
                Icons.logout, // Using a standard logout icon
                color: primaryDarkColor, // Icon color matches accent
                size: 30,
              ),
            ),
            const SizedBox(height: 20), // Increased spacing
            // Title text
            Text(
              '$title',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
'$subtitle',              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 25), // Spacing before buttons
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Obx(
                    () => // Obx to react to logoutLoading state
                        DarkThemeDialogButton(
                      text:
                          authController.logoutLoading.value
                              ? "Logging Out..."
                              : "Logout",
                      onPressed:
                          authController.logoutLoading.value
                              ? null
                              : () {
                                authController.logout();
                              },
                      // Use a primary color for the action button
                      buttonColor: primaryDarkColor,
                      textColor: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 15), // Space between buttons
                Expanded(
                  child: DarkThemeDialogButton(
                    text: "Cancel",
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    buttonColor:
                        dialogBackgroundColor, // Transparent background
                    textColor: primaryDarkColor, // Accent text color
                    borderColor: primaryDarkColor, // Accent border
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Redesigned Button Widget for Dark Theme ---
class DarkThemeDialogButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color buttonColor;
  final Color textColor;
  final Color? borderColor;
  const DarkThemeDialogButton({
    required this.text,
    required this.onPressed,
    required this.buttonColor,
    required this.textColor,
    this.borderColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(0),
        alignment: Alignment.center,
        side: MaterialStateProperty.all(
          BorderSide(
            width: 1,
            color: borderColor ?? buttonColor,
          ), 
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ), 
        ),
        backgroundColor: MaterialStateProperty.all(buttonColor),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        overlayColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.pressed)) {
            return textColor.withOpacity(0.1); // Ripple effect color
          }
          return null; // Defer to the widget's default.
        }),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 15, 
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
