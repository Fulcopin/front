import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class WebSafeImage extends StatelessWidget {
  final File? imageFile;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color fallbackColor;

  const WebSafeImage({
    Key? key,
    required this.imageFile,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackColor = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageFile == null) {
      return Container(
        width: width,
        height: height,
        color: fallbackColor,
      );
    }

    return kIsWeb 
      ? Image.network(
          imageFile!.path,
          width: width,
          height: height,
          fit: fit,
        )
      : Image.file(
          imageFile!,
          width: width,
          height: height,
          fit: fit,
        );
  }
}