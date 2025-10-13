import 'package:get/get.dart';

import '../../../../utils/dummy_helper.dart';
import '../../../data/models/product_model.dart';
import '../../cart/controllers/cart_controller.dart';

class BaseController extends GetxController {
  int currentIndex = 0;
  int cartItemsCount = 0;

  @override
  void onInit() {
    getCartItemsCount();
    super.onInit();
  }

  changeScreen(int selectedIndex) {
    currentIndex = selectedIndex;
    update();
  }

  getCartItemsCount() {
    final products = DummyHelper.products;
    cartItemsCount = products.fold<int>(0, (p, c) => p + c.quantity);
    update(['CartBadge']);
  }

  /// New: add if missing, else increase. Works for Firestore or dummy items.
  void addOrIncrease(ProductModel product) {
    final list = DummyHelper.products;
    final idx = list.indexWhere((p) => p.id == product.id);

    if (idx == -1) {
      // Ensure we add with at least quantity 1
      product.quantity = (product.quantity > 0) ? product.quantity : 1;
      list.add(product);
    } else {
      list[idx].quantity++;
    }

    getCartItemsCount();
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().getCartProducts();
    }
    update(['ProductQuantity', 'CartBadge']);
  }

  /// Existing + button (works after the first add)
  onIncreasePressed(int productId) {
    final p = DummyHelper.products.firstWhere((p) => p.id == productId);
    p.quantity++;
    getCartItemsCount();
    update(['ProductQuantity']);
  }

  onDecreasePressed(int productId) {
    final product = DummyHelper.products.firstWhere((p) => p.id == productId);
    if (product.quantity > 0) {
      product.quantity--;
      getCartItemsCount();
      if (Get.isRegistered<CartController>()) {
        Get.find<CartController>().getCartProducts();
      }
      update(['ProductQuantity']);
    }
  }
}
