// // ignore_for_file: deprecated_member_use


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../components/product_item.dart';


class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final categoryName =
        Get.arguments as String; // Get the category name passed as an argument

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Get.back(),
              ),
              Text(
                '$categoryName 🌽', // Display the selected category name in the title
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
      body: Obx(
        () {
          if (controller.products.isEmpty) {
            return const Center(
                child: Text(
                    'No products available')); // Display message if no products are available
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Display two products per row
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 214, // Fixed height for each grid item
              ),
              itemCount: controller.products.length,
              itemBuilder: (context, index) {
                final product = controller
                    .products[index]; // Get the product at the current index
                return ProductItem(
                  product:
                      product, // Pass the product to the ProductItem widget
                );
              },
            ),
          );
        },
      ),
    );
  }
}
