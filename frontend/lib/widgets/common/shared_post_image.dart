import 'package:flutter/material.dart';

import '../../utils/post_image_path.dart';

class SharedPostImage extends StatelessWidget {
  const SharedPostImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() =>
        fallback ??
        Image.asset(postImageFallback, width: width, height: height, fit: fit);

    final displayPath = postImageDisplayPath(path);
    if (isPostImageAsset(displayPath)) {
      return Image.asset(
        displayPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    if (isSharedPostImage(displayPath)) {
      return Image.network(
        displayPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder(),
      );
    }
    return placeholder();
  }
}
