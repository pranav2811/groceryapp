// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../components/product_item.dart';

class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final categoryName = Get.arguments as String;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Get.back(),
              ),
              Text(
                '$categoryName 🌽',
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                icon: Icon(Icons.search, color: theme.iconTheme.color),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (controller.products.isEmpty) {
          return const Center(child: Text('No products available'));
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 214,
            ),
            itemCount: controller.products.length,
            itemBuilder: (context, index) {
              final product = controller.products[index];
              final imageUrls =
                  controller.imageUrlsById[product.id] ?? const <String>[];

              return ProductItem(
                product: product,
                imageUrls: imageUrls, // <-- pass full list to item
              );
            },
          ),
        );
      }),
    );
  }
}
