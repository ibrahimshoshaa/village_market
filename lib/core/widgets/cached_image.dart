import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (_, __) => _shimmer(),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _shimmer() => Container(
        width: width,
        height: height,
        color: AppColors.shimmerBase,
      );

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: AppColors.imagePlaceholderBg,
        child: const Icon(
          Icons.image_not_supported_outlined,
          color: AppColors.imagePlaceholderIcon,
        ),
      );
}
