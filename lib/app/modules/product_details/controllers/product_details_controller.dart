import 'package:get/get.dart';

import '../../../data/models/product_model.dart';
import '../../base/controllers/base_controller.dart';

class ProductDetailsController extends GetxController {

  // get product details from arguments
  ProductModel product = Get.arguments;

  onAddToCartPressed() {
    Get.find<BaseController>().addOrIncrease(product);
    Get.back();
  }

}
