import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

class CircleImage extends StatelessWidget {
  final double radius;
  final String? url;
  final XFile? file; 

  const CircleImage({
    super.key,
    this.radius = 20,
    this.url,
    this.file,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (url != null && url!.isNotEmpty) {
      avatar = CircleAvatar(
        backgroundImage: NetworkImage(url!),
        radius: radius,
      );
    } else if (file != null) {
      avatar = kIsWeb
          ? FutureBuilder<Uint8List>(
              future: file!.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return CircleAvatar(
                    radius: radius,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return CircleAvatar(
                  backgroundImage: MemoryImage(snapshot.data!),
                  radius: radius,
                );
              },
            )
          : CircleAvatar(
              backgroundImage: FileImage(io.File(file!.path)),
              radius: radius,
            );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: const AssetImage("assets/images/avatar.png"),
        
      );
    }

    return avatar;
  }
}
