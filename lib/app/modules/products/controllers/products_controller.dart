import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:groceryapp/app/data/models/product_model.dart';

class ProductsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Observable list of ProductModels
  var products = <ProductModel>[].obs;

  /// Fetch products from Firestore based on the selected category name
  Future<void> fetchProducts(String categoryName) async {
    try {
      final productsSnapshot = await _firestore
          .collection('inventory')
          .doc(categoryName)
          .collection('items')
          .get();

      final fetchedProducts = productsSnapshot.docs.map((doc) {
        final data = doc.data();

        // Safely map Firestore fields to your ProductModel
        return ProductModel(
          id: data['id'] ?? 0,
          image: data['image'] ?? '',
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          quantity: data['quantity'] ?? 0,
          price: (data['price'] is num)
              ? (data['price'] as num).toDouble()
              : double.tryParse(data['price'].toString()) ?? 0.0,
        );
      }).toList();

      products.assignAll(fetchedProducts);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products');
    }
  }
}
