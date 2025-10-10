// // ignore_for_file: deprecated_member_use

// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:get/get.dart';

// import '../../../../utils/constants.dart';
// import '../../../components/custom_icon_button.dart';
// import '../../../components/product_item.dart';
// import '../controllers/products_controller.dart';

// class ProductsView extends GetView<ProductsController> {
//   const ProductsView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = context.theme;
//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         title: Padding(
//           padding: EdgeInsets.symmetric(horizontal: 8.w),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               CustomIconButton(
//                 onPressed: () => Get.back(),
//                 backgroundColor: theme.scaffoldBackgroundColor,
//                 borderColor: theme.dividerColor,
//                 icon: SvgPicture.asset(
//                   Constants.backArrowIcon,
//                   fit: BoxFit.none,
//                   color: theme.appBarTheme.iconTheme?.color,
//                 ),
//               ),
//               Text(
//                 'Vegetables 🌽',
//                 style: theme.textTheme.bodyMedium,
//               ),
//               CustomIconButton(
//                 onPressed: () {},
//                 backgroundColor: theme.scaffoldBackgroundColor,
//                 borderColor: theme.dividerColor,
//                 icon: SvgPicture.asset(
//                   Constants.searchIcon,
//                   fit: BoxFit.none,
//                   color: theme.appBarTheme.iconTheme?.color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
//         child: GridView.builder(
//           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             crossAxisSpacing: 16.w,
//             mainAxisSpacing: 16.h,
//             mainAxisExtent: 214.h,
//           ),
//           shrinkWrap: true,
//           primary: false,
//           itemCount: controller.products.length,
//           itemBuilder: (context, index) => ProductItem(
//             product: controller.products[index],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/products_controller.dart';
import '../../../components/product_item.dart';
import 'package:groceryapp/app/data/models/product_model.dart';


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
