import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import for Firebase Auth
import '../../../../utils/dummy_helper.dart';
import '../../../components/custom_snackbar.dart';
import '../../../data/models/product_model.dart';
import '../../base/controllers/base_controller.dart';
import '../../../../widgets/add_address_bottom_sheet.dart';
import 'package:flutter/material.dart';

class CartController extends GetxController {
  // to hold the products in cart
  List<ProductModel> products = [];
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    getCartProducts();
    super.onInit();
  }

  /// when the user presses on the purchase now button
  onPurchaseNowPressed(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      CustomSnackBar.showCustomSnackBar(
        title: 'Error',
        message: 'User not logged in. Please log in to place an order.',
      );
      return;
    }

    if (products.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return AddAddressBottomSheet(
            userId: userId,
          );
        },
      ).then((address) async {
        if (address != null && address is Map<String, dynamic>) {
          await addOrderToFirestore(userId, address);
          clearCart();
          Get.back();
          CustomSnackBar.showCustomSnackBar(
              title: 'Purchased', message: 'Order placed with success');
        } else {
          CustomSnackBar.showCustomSnackBar(
              title: 'Error',
              message: 'Order cancelled or no address provided');
        }
      });
    } else {
      CustomSnackBar.showCustomSnackBar(
          title: 'Empty Cart', message: 'No items to place in the order');
    }
  }

  Future<void> addOrderToFirestore(
      String userId, Map<String, dynamic> address) async {
    try {
      await firestore.collection('orders').add({
        // use both keys for backward compatibility
        'userId': userId, // ← used by rules and orders screen
        'user_id': userId, // ← your existing data shape
        'address': address,
        'products': products
            .map((p) => {
                  'name': p.name,
                  'price': p.price,
                  'quantity': p.quantity,
                  'image': p.image,
                })
            .toList(),
        'payment_status': 'pending',
        'paymentMethod': 'cod',
        'createdAt': FieldValue.serverTimestamp(), // ← for sorting
      });

      CustomSnackBar.showCustomSnackBar(
        title: 'Success',
        message: 'Order placed successfully!',
      );
    } catch (e) {
      CustomSnackBar.showCustomSnackBar(
        title: 'Error',
        message: 'Failed to place order: $e',
      );
    }
  }

  /// get the cart products from the product list
  getCartProducts() {
    products = DummyHelper.products.where((p) => p.quantity > 0).toList();
    update();
  }

  /// clear products in cart and reset cart items count
  clearCart() {
    DummyHelper.products.map((p) => p.quantity = 0).toList();
    Get.find<BaseController>().getCartItemsCount();
  }
}
