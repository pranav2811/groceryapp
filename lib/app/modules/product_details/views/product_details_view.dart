// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../utils/constants.dart';
import '../../../../utils/dummy_helper.dart';
import '../../../components/custom_button.dart';
import '../../../components/custom_card.dart';
import '../../../components/custom_icon_button.dart';
import '../../../components/product_count_item.dart';
import '../controllers/product_details_controller.dart';

class ProductDetailsView extends GetView<ProductDetailsController> {
  const ProductDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final rawImgs = controller.imageUrls;
// try to skip the disclaimer
    final imgsAfterSkip = rawImgs.length > 1
        ? rawImgs.sublist(1).where((e) => e.trim().isNotEmpty).toList()
        : const <String>[];

// final list we'll actually show
    final imgs = imgsAfterSkip.isNotEmpty ? imgsAfterSkip : rawImgs;
    Widget buildProductImage(String path) {
      final isNetwork =
          path.startsWith('http://') || path.startsWith('https://');
      if (isNetwork) {
        return Image.network(
          path,
          width: 250.w,
          height: 225.h,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 64, color: Colors.grey),
        );
      }
      return Image.asset(
        path,
        width: 250.w,
        height: 225.h,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
      );
    }

    Widget buildImages() {
      // we have multiple from Firestore
      if (imgs.isNotEmpty) {
        if (imgs.length == 1) {
          return buildProductImage(imgs.first);
        }
        return SizedBox(
          height: 225.h,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.8),
            itemCount: imgs.length,
            itemBuilder: (ctx, i) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: buildProductImage(imgs[i]),
            ),
          ),
        );
      }
      // fallback to single image on the product
      return buildProductImage(controller.product.image);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            SizedBox(
              height: 330.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SvgPicture.asset(
                      Constants.container,
                      fit: BoxFit.fill,
                      color: theme.cardColor,
                    ),
                  ),
                  Positioned(
                    top: 24.h,
                    left: 24.w,
                    right: 24.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomIconButton(
                          onPressed: () => Get.back(),
                          icon: SvgPicture.asset(
                            Constants.backArrowIcon,
                            fit: BoxFit.none,
                            color: theme.appBarTheme.iconTheme?.color,
                          ),
                        ),
                        CustomIconButton(
                          onPressed: () {},
                          icon: SvgPicture.asset(
                            Constants.searchIcon,
                            fit: BoxFit.none,
                            color: theme.appBarTheme.iconTheme?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 80.h,
                    left: 0,
                    right: 0,
                    child: buildImages()
                        .animate()
                        .fade()
                        .scale(duration: 800.ms, curve: Curves.fastOutSlowIn),
                  ),
                ],
              ),
            ),
            30.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.product.name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ).animate().fade().slideX(
                          duration: 300.ms,
                          begin: -1,
                          curve: Curves.easeInSine,
                        ),
                  ),
                  12.horizontalSpace,
                  SizedBox(
                    width: 120.w,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ProductCountItem(product: controller.product)
                          .animate()
                          .fade(duration: 200.ms),
                    ),
                  ),
                ],
              ),
            ),
            8.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                '1kg, ${controller.product.price.toStringAsFixed(2)}\$',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.primaryColor,
                ),
              ).animate().fade().slideX(
                    duration: 300.ms,
                    begin: -1,
                    curve: Curves.easeInSine,
                  ),
            ),
            8.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                controller.product.description,
                style: theme.textTheme.bodySmall,
              ).animate().fade().slideX(
                    duration: 300.ms,
                    begin: -1,
                    curve: Curves.easeInSine,
                  ),
            ),
            20.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: GridView(
                shrinkWrap: true,
                primary: false,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.w,
                  mainAxisSpacing: 16.h,
                  mainAxisExtent: 80.h,
                ),
                children: DummyHelper.cards
                    .map((card) => CustomCard(
                          title: card['title']!,
                          subtitle: card['subtitle']!,
                          icon: card['icon']!,
                        ))
                    .toList()
                    .animate()
                    .fade()
                    .slideY(
                      duration: 300.ms,
                      begin: 1,
                      curve: Curves.easeInSine,
                    ),
              ),
            ),
            30.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: CustomButton(
                text: 'Add to cart',
                onPressed: () => controller.onAddToCartPressed(),
                fontSize: 16.sp,
                radius: 50.r,
                verticalPadding: 16.h,
                hasShadow: false,
              ).animate().fade().slideY(
                    duration: 300.ms,
                    begin: 1,
                    curve: Curves.easeInSine,
                  ),
            ),
            30.verticalSpace,
          ],
        ),
      ),
    );
  }
}
