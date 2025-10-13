import 'package:get/get.dart';

import '../../../../utils/dummy_helper.dart';
import '../../../data/models/product_model.dart';
import '../../cart/controllers/cart_controller.dart';

class BaseController extends GetxController {
  int currentIndex = 0;
  int cartItemsCount = 0;

  @override
  void onInit() {
    super.onInit();
    getCartItemsCount();
  }

  // ------- Navigation -------
  void changeScreen(int selectedIndex) {
    currentIndex = selectedIndex;
    update();
  }

  // ------- Cart counters / refresh -------
  void getCartItemsCount() {
    final products = DummyHelper.products;
    cartItemsCount = products.fold<int>(0, (p, c) => p + c.quantity);
    update(['CartBadge']);
  }

  void _refreshCartViews() {
    getCartItemsCount();
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().getCartProducts();
    }
    update(['ProductQuantity', 'CartBadge']);
  }

  int _indexById(int productId) =>
      DummyHelper.products.indexWhere((p) => p.id == productId);

  void addOrIncrease(ProductModel product) {
    final list = DummyHelper.products;
    final idx = _indexById(product.id);

    if (idx == -1) {

      final initialQty = (product.quantity > 0) ? product.quantity : 1;

      product.quantity = initialQty;
      list.add(product);
    } else {
      list[idx].quantity++;
    }

    _refreshCartViews();
  }


  void onIncreasePressed(int productId) {
    final idx = _indexById(productId);
    if (idx == -1) {
      
      return;
    }
    DummyHelper.products[idx].quantity++;
    _refreshCartViews();
  }

  void onDecreasePressed(int productId) {
    final idx = _indexById(productId);
    if (idx == -1) return;

    final item = DummyHelper.products[idx];
    if (item.quantity > 0) {
      item.quantity--;
      // Optional: remove from list when it hits zero
      // if (item.quantity == 0) {
      //   DummyHelper.products.removeAt(idx);
      // }
      _refreshCartViews();
    }
  }
}
