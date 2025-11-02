import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../components/product_count_item.dart';
import '../../../../data/models/product_model.dart';
import '../../controllers/cart_controller.dart';

class CartItem extends GetView<CartController> {
  final ProductModel product;
  const CartItem({super.key, required this.product});

  bool _isUrl(String s) {
    final v = s.toLowerCase();
    return v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('gs://') ||
        v.contains('firebasestorage.googleapis.com');
  }

  Widget _thumb(String path) {
    final size = Size(56.w, 56.w);
    final border = BorderRadius.circular(8.r);

    if (_isUrl(path)) {
      // Network image (http/https). If you use gs://, see note below.
      return ClipRRect(
        borderRadius: border,
        child: FadeInImage.assetNetwork(
          placeholder:
              'assets/placeholder.jpg', // ensure declared in pubspec.yaml
          image: path,
          width: size.width,
          height: size.height,
          fit: BoxFit.cover,
          imageErrorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 32, color: Colors.grey),
        ),
      );
    }

    // Local asset
    return ClipRRect(
      borderRadius: border,
      child: Image.asset(
        path,
        width: size.width,
        height: size.height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 32, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _thumb(product.image),
          12.horizontalSpace,
          // Use Expanded so long titles don't push buttons off-screen
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  '\₹${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          ProductCountItem(product: product),
        ],
      ),
    );
  }
}
