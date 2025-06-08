import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:thread_app/Services/navigation_service.dart';

import 'package:thread_app/controller/profile_controller.dart';
import 'package:thread_app/controller/thread_controller.dart';
import 'package:thread_app/widgets/image_circle.dart';
import 'package:thread_app/widgets/video_preview.dart';

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
            crossAxisAlignment: CrossAxisAlignment.start,
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
              _buildMediaPreviews(), // This will now display both images and video
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
                  child: CircularProgressIndicator.adaptive(),
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
      ),
      child: Obx(
        () => Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleImage(radius: 25, url: profileController.userAvatarUrl.value),
            const SizedBox(
              width: 15,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.start, // Align children to the start of the column.
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align children to the start (left) within the column.
                children: [
                  Text(
                    profileController.userName.value,
                    // Applies a bold title style from the current theme.
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white30,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller:
              threadController.addtextEditingController,
          autofocus: true,
          onChanged: (val) {
            threadController.content.value = val;
          },
          style: Theme.of(Get.context!)
              .textTheme
              .bodyLarge, // Applies text style from the current theme.
          maxLines:
              null,
          minLines: 1,
          maxLength: _maxThreadCharacters, 
          decoration: InputDecoration(
            hintText: "Start a thread...", 
            hintStyle: Theme.of(
              Get.context!,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: "",
          ),
        ),
        Obx(() {
          final currentLength = threadController.content.value.length;
          final remaining = _maxThreadCharacters - currentLength;
          return Text(
            '$remaining characters remaining',
            style: TextStyle(
              fontSize: 12,
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
            // Disable if the maximum number of images is already picked.
            isDisabled: hasMaxImages,
          ),
          const SizedBox(width: 15),
          // Button for picking a single video from the gallery.
          _mediaButton(
            icon: CupertinoIcons.video_camera,
            label: 'Video',
            onTap: threadController.pickVideo,
            // Disable if a video is already picked.
            isDisabled: hasVideo,
          ),
          const SizedBox(width: 15),
          // Button for taking a photo using the device's camera.
          _mediaButton(
            icon: CupertinoIcons.camera,
            label: 'Camera',
            onTap: threadController.takePhoto,
            // Disable if the maximum number of images is already picked.
            isDisabled: hasMaxImages,
          ),
          const SizedBox(width: 15),
          // Button for recording a video using the device's camera.
          _mediaButton(
            icon: CupertinoIcons.videocam,
            label: 'Record',
            onTap: threadController.recordVideo,
            // Disable if a video is already picked.
            isDisabled: hasVideo,
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
            color: isDisabled
                ? Colors.grey
                : Theme.of(Get.context!).iconTheme.color,
          ),
          onPressed: isDisabled ? null : onTap,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            // Changes label color based on its disabled state.
            color: isDisabled
                ? Colors.grey
                : Theme.of(Get.context!).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  // Builds and displays the selected media previews (either images, a video, or both).
  Widget _buildMediaPreviews() {
    return Obx(() {
      final bool hasVideo = threadController.video.value != null;
      final bool hasImages = threadController.images.isNotEmpty;

      if (!hasVideo && !hasImages) {
        return const SizedBox(); 
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasVideo) ...[
            _videoPreview(threadController.video.value!),
            if (hasImages) const SizedBox(height: 15), 
          ],
          if (hasImages) _imagePreviews(threadController.images),
        ],
      );
    });
  }

  // Displays a grid of selected image previews.
  Widget _imagePreviews(RxList<XFile> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageFile = images[index];
        return _mediaPreviewCard(
          child: kIsWeb
              ? Image.network(
                  imageFile.path,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                )
              : Image.file(
                  File(
                    imageFile.path,
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
          onRemove: () => threadController.removeImage(
            index,
          ),
        );
      },
    );
  }

  Widget _videoPreview(XFile videoFile) {
    return VideoPreviewPlayer(
      videoFile: videoFile,
      onRemove: () => threadController.removeVideo(),
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
      ),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          SizedBox.expand(
            child: child,
          ),
          Positioned(
            right: 5,
            top: 5,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(
                  4,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}