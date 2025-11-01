import 'package:get/get.dart';

import '../../../data/models/product_model.dart';
import '../../base/controllers/base_controller.dart';

class ProductDetailsController extends GetxController {
  late final ProductModel product;
  List<String> imageUrls = const [];

  @override
  void onInit() {
    final args = Get.arguments;
    if (args is Map) {
      product = args['product'] as ProductModel;
      final imgs = args['imageUrls'];
      if (imgs is List) {
        imageUrls = imgs.map((e) => e.toString()).toList();
      }
    } else {
      product = args as ProductModel;
    }
    super.onInit();
  }

  void onAddToCartPressed() {
    Get.find<BaseController>().addOrIncrease(product);
    Get.back();
  }
}
