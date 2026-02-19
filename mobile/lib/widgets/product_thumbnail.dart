import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const ProductThumbnail({
    super.key,
    this.imageUrl,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.image_not_supported, size: 20, color: AppTheme.primaryColor),
              ),
            )
          : const Icon(Icons.image, size: 20, color: AppTheme.primaryColor),
    );
  }
}
