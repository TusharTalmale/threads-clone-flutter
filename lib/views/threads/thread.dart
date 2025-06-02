import 'dart:io'; // Required for File operations (Image.file)

import 'package:flutter/cupertino.dart'; // For CupertinoIcons
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart'; // For Material Design widgets
import 'package:get/get.dart'; // For GetX state management
import 'package:image_picker/image_picker.dart'; // Required for XFile type
import 'package:thread_app/Services/navigation_service.dart';

import 'package:thread_app/controller/profile_controller.dart'; 
import 'package:thread_app/controller/thread_controller.dart'; 
import 'package:thread_app/widgets/image_circle.dart'; 

class AddThread extends StatelessWidget {
  AddThread({super.key});


  final ProfileController profileController = Get.put(ProfileController());
  final ThreadController threadController = Get.put(ThreadController());

  final int _maxThreadCharacters = 500;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ), 
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const SizedBox(
                height: 20,
              ), 
              _profileRow(
                profileController,
              ),
              const SizedBox(
                height: 10,
              ), 
              _buildTextField(), 
              const SizedBox(
                height: 10,
              ), 
              _buildMediaSelectionButtons(), 
              const SizedBox(
                height: 15,
              ), 
              _buildMediaPreviews(),
            ],
          ),
        ),
      ),
    );
  }
PreferredSizeWidget _buildAppBar() {
  final context = Get.context;
  final TextStyle defaultStyle = const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );

  return AppBar(
    title: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Get.find<NavigationService>().backToPrevPage();
                },
                icon: const Icon(Icons.close),
              ),
              const SizedBox(width: 8),
              Text(
                "New Thread",
                style: context != null
                    ? Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)
                    : defaultStyle,
              ),
            ],
          ),
          Obx(() {
            if (threadController.posting.value == true) {
              return const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator.adaptive(
                ),
              );
            } else {
              return TextButton(
                onPressed: threadController.canPost
                    ? () => threadController.postThread()
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: threadController.canPost
                      ? Colors.blueAccent
                      : Colors.grey,
                ),
                child: Text(
                  'Post',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: threadController.canPost
                        ? Colors.blueAccent
                        : Colors.grey,
                  ),
                ),
              );
            }
          }),
        ],
      ),
    ),
  );
}

  // Builds the row displaying the user's profile picture and name.
  Widget _profileRow(ProfileController profileController) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ), // Vertical padding for the entire row.
      child: Obx(
        // Obx observes changes in profileController's reactive variables.
        () => Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .start, // Align children to the start of the row.
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to the top of the row.
          children: [
            // CircleImage is a custom widget assumed to display a circular profile image.
            CircleImage(radius: 25, url: profileController.userAvatarUrl.value),
            const SizedBox(
              width: 15,
            ), // Space between the profile image and the text.
            Expanded(
              // Expanded ensures the Column takes up the remaining available width, allowing text to wrap.
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .start, // Align children to the start of the column.
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start, // Align children to the start (left) within the column.
                children: [
                  Text(
                    profileController.userName.value,
                    // Applies a bold title style from the current theme.
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white30,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4), // Small vertical space.
                  // You could add "Add to thread" or other elements here if desired.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the text input field for the thread content and the live character counter.
  Widget _buildTextField() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.end, // Aligns the character counter to the right.
      children: [
        TextField(
          controller:
              threadController
                  .addtextEditingController, // Links the TextField to the controller.
          autofocus:
              true, // Automatically focuses the text field when the page loads.
          onChanged: (val) {
            threadController.content.value =
                val; // Updates the reactive 'content' variable in the controller.
          },
          style:
              Theme.of(Get.context!)
                  .textTheme
                  .bodyLarge, // Applies text style from the current theme.
          maxLines:
              null, // Allows the text field to expand vertically for unlimited lines.
          minLines: 1, // Ensures the text field always shows at least one line.
          maxLength:
              _maxThreadCharacters, // Enforces the defined character limit.
          decoration: InputDecoration(
            hintText:
                "Start a thread...", // Placeholder text when the field is empty.
            hintStyle: Theme.of(
              Get.context!,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            border:
                InputBorder
                    .none, // Removes the default border around the text field.
            contentPadding:
                EdgeInsets
                    .zero, // Removes default internal padding of the TextField.
            counterText:
                "", // Hides the default character counter provided by TextField, as we have a custom one.
          ),
        ),
        // Obx reactively displays the remaining characters based on the 'content' length.
        Obx(() {
          final currentLength = threadController.content.value.length;
          final remaining = _maxThreadCharacters - currentLength;
          return Text(
            '$remaining characters remaining',
            style: TextStyle(
              fontSize: 12,
              // Changes text color to red if few characters are remaining to warn the user.
              color: remaining < 20 ? Colors.red : Colors.grey,
            ),
          );
        }),
      ],
    );
  }

  // Builds the row of buttons for selecting different media types (photos, video, camera).
  Widget _buildMediaSelectionButtons() {
    return Obx(() {
      final bool hasVideo = threadController.video.value != null;
      final bool hasMaxImages = threadController.images.length >= 3;

      return Row(
        children: [
          // Button for picking multiple photos from the gallery.
          _mediaButton(
            icon: CupertinoIcons.photo_on_rectangle,
            label: 'Photos',
            onTap: threadController.pickImages,
            // Disable if a video is selected or the maximum number of images is already picked.
            isDisabled: hasVideo || hasMaxImages,
          ),
          const SizedBox(width: 15), // Space between buttons.
          // Button for picking a single video from the gallery.
          _mediaButton(
            icon: CupertinoIcons.video_camera,
            label: 'Video',
            onTap: threadController.pickVideo,
            // Disable if images are already selected or a video is already picked.
            isDisabled: threadController.images.isNotEmpty || hasVideo,
          ),
          const SizedBox(width: 15), // Space between buttons.
          // Button for taking a photo using the device's camera.
          _mediaButton(
            icon: CupertinoIcons.camera,
            label: 'Camera',
            onTap: threadController.takePhoto,
            // Disable if a video is selected or the maximum number of images is already picked.
            isDisabled: hasVideo || hasMaxImages,
          ),
          const SizedBox(width: 15), // Space between buttons.
          // Button for recording a video using the device's camera.
          _mediaButton(
            icon: CupertinoIcons.videocam,
            label: 'Record',
            onTap: threadController.recordVideo,
            // Disable if images are already selected or a video is already picked.
            isDisabled: threadController.images.isNotEmpty || hasVideo,
          ),
        ],
      );
    });
  }

  // Helper widget to create a consistent media selection button style.
  Widget _mediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap, 
    required bool isDisabled,
  }) {
    return Column(
      children: [
        IconButton(
          icon: Icon(
            icon,
            size: 28,
            // Changes icon color based on its disabled state.
            color:
                isDisabled
                    ? Colors.grey
                    : Theme.of(Get.context!).iconTheme.color,
          ),
          onPressed:
              isDisabled
                  ? null
                  : onTap, // If disabled, onPressed is null, making it non-interactive.
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            // Changes label color based on its disabled state.
            color:
                isDisabled
                    ? Colors.grey
                    : Theme.of(Get.context!).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  // Builds and displays the selected media previews (either images or a video).
  Widget _buildMediaPreviews() {
    return Obx(() {
      // If a video is selected, show the video preview.
      if (threadController.video.value != null) {
        return _videoPreview(threadController.video.value!);
      }
      // If images are selected, show the image previews in a grid.
      else if (threadController.images.isNotEmpty) {
        return _imagePreviews(threadController.images);
      }
      // If no media is selected, return an empty SizedBox to take no space.
      else {
        return const SizedBox();
      }
    });
  }

  // Displays a grid of selected image previews.
  Widget _imagePreviews(RxList<XFile> images) {
    return GridView.builder(
      shrinkWrap:
          true, 
      physics:
          const NeverScrollableScrollPhysics(), // Disables scrolling within the grid itself.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 10, // Horizontal space between images.
        mainAxisSpacing: 10, // Vertical space between images.
        childAspectRatio: 1.0, // Makes each image preview square.
      ),
      itemCount: images.length, // Number of images to display.
      itemBuilder: (context, index) {
        final imageFile = images[index];
        return _mediaPreviewCard(
          child:
              kIsWeb // Checks if the app is running on the web platform.
                  ? Image.network(
                    imageFile
                        .path, // Use Image.network for web (path is a URL).
                    fit: BoxFit.cover, // Covers the entire space.
                    alignment: Alignment.center, // Centers the image.
                  )
                  : Image.file(
                    File(
                      imageFile.path,
                    ), // Use Image.file for mobile (path is a file path).
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
          onRemove:
              () => threadController.removeImage(
                index,
              ), // Callback to remove this specific image.
        );
      },
    );
  }

  // Displays a placeholder for the selected video preview.
  Widget _videoPreview(XFile videoFile) {
    // For a real video preview, you would integrate the 'video_player' package here
    // and use a VideoPlayerController to display the video.
    // For now, we show a dark background with a play icon as a visual indicator.
    return _mediaPreviewCard(
      child: Stack(
        alignment: Alignment.center, // Centers the play icon within the stack.
        children: [
          Container(
            color: Colors.black, // Dark background for the video placeholder.
            child: const Center(
              child: Icon(
                Icons.play_circle_fill, // A prominent play icon.
                color:
                    Colors.white70, // Slightly transparent white for the icon.
                size: 60, // Large icon size.
              ),
            ),
          ),
          // If you had a way to extract a thumbnail from XFile, you could place it here.
          // Example: Image.file(File(videoFile.thumbnailPath), fit: BoxFit.cover)
        ],
      ),
      onRemove:
          () =>
              threadController
                  .removeVideo(), // Callback to remove the selected video.
    );
  }

  // Helper widget to wrap media previews with a close button for removal.
  Widget _mediaPreviewCard({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        10,
      ), // Applies rounded corners to the preview card.
      child: Stack(
        alignment:
            Alignment
                .topRight, // Positions the close button at the top-right corner.
        children: [
          SizedBox.expand(
            child: child,
          ), // Ensures the child (image/video) fills the entire card.
          Positioned(
            right: 5, // Offset from the right edge.
            top: 5, // Offset from the top edge.
            child: GestureDetector(
              onTap:
                  onRemove, // Calls the provided remove callback when the button is tapped.
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Colors
                          .black54, // Semi-transparent black background for the close button.
                  shape: BoxShape.circle, // Makes the container circular.
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ), // White border around the button.
                ),
                padding: const EdgeInsets.all(
                  4,
                ), // Padding around the icon inside the button.
                child: const Icon(
                  Icons.close, // The close icon.
                  color: Colors.white, // White color for the icon.
                  size: 18, // Size of the close icon.
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
