import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:groceryapp/app/data/models/product_model.dart';

import '../routes/app_pages.dart';

class ProductItem extends StatelessWidget {
  final ProductModel product;
  final List<String> imageUrls; // <-- new

  const ProductItem({
    super.key,
    required this.product,
    this.imageUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return GestureDetector(
      onTap: () => Get.toNamed(
        Routes.productDetails,
        arguments: {
          'product': product,
          'imageUrls': imageUrls,
        },
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 12.w,
              bottom: 12.h,
              child: GestureDetector(
                onTap: () => Get.toNamed(
                  Routes.productDetails,
                  arguments: {
                    'product': product,
                    'imageUrls': imageUrls,
                  },
                ),
                child: CircleAvatar(
                  radius: 18.r,
                  backgroundColor: theme.primaryColor,
                  child: const Icon(Icons.add_rounded, color: Colors.white),
                ).animate().fade(duration: 200.ms),
              ),
            ),
            Positioned(
              top: 22.h,
              left: 26.w,
              right: 25.w,
              child: Image.network(
                product.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.broken_image,
                      size: 80.r, color: Colors.grey);
                },
              ).animate().slideX(
                    duration: 200.ms,
                    begin: 1,
                    curve: Curves.easeInSine,
                  ),
            ),
            Positioned(
              left: 16.w,
              bottom: 24.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ).animate().fade().slideY(
                        duration: 200.ms,
                        begin: 1,
                        curve: Curves.easeInSine,
                      ),
                  5.verticalSpace,
                  Text(
                    '\₹${product.price}',
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ).animate().fade().slideY(
                        duration: 200.ms,
                        begin: 2,
                        curve: Curves.easeInSine,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
