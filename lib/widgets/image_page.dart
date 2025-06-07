import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShowImage extends StatelessWidget {
  final String? imageurl = Get.arguments;

    ShowImage({super.key });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image'),
      ),
      body: 
      SizedBox(
        height: double.infinity,
        width: double.infinity,
        child: Image.network(imageurl ?? ' Not generating ' , fit: BoxFit.contain,),

      ),
    );
  }
}