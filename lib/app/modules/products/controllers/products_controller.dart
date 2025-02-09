// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// import 'package:groceryapp/models/product.dart'; // Import your updated Product model

// class ProductsController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   var products = <Product>[].obs; // Observable list to hold products

//   /// Fetch products from Firestore based on the selected category name
//   void fetchProducts(String categoryName) async {
//     try {
//       final productsSnapshot = await _firestore
//           .collection('inventory')
//           .doc(categoryName)
//           .collection('items')
//           .get();

//       final fetchedProducts = productsSnapshot.docs.map((doc) {
//         // Using Product.fromMap to create instances from Firestore data
//         return Product.fromMap(doc.data() as Map<String, dynamic>);
//       }).toList();

//       // Assigning the fetched products to the observable list
//       products.assignAll(fetchedProducts);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load products');
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:groceryapp/models/product.dart'; // Import your updated Product model

class ProductsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var products = <Product>[].obs; // Observable list to hold products

  /// Fetch products from Firestore based on the selected category name
  void fetchProducts(String categoryName) async {
    try {
      // Fetch the items in the specified category from Firestore
      final productsSnapshot = await _firestore
          .collection('inventory')
          .doc(categoryName)
          .collection('items')
          .get();

      // Map each document to a Product instance using the fromMap factory constructor
      final fetchedProducts = productsSnapshot.docs.map((doc) {
        return Product.fromMap(doc.data());
      }).toList();

      // Update the observable list with the fetched products
      products.assignAll(fetchedProducts);
    } catch (e) {
      // Show an error message if there was an issue fetching data
      Get.snackbar('Error', 'Failed to load products');
    }
  }
}
