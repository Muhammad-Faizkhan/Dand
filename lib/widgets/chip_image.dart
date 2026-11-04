import 'package:flutter/material.dart';
import '../models/models.dart';

/// The chip's uploaded photo when it has one, otherwise its bundled artwork.
class ChipImage extends StatelessWidget {
  const ChipImage(this.item, {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center, this.width, this.height});

  final ChipItem item;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final asset = Image.asset(item.image, fit: fit, alignment: alignment, width: width, height: height);
    final url = item.imageUrl;
    if (url == null) return asset;
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      width: width,
      height: height,
      errorBuilder: (_, _, _) => asset,
    );
  }
}
