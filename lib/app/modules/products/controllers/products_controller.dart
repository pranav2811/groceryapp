import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:groceryapp/app/data/models/product_model.dart';

class ProductsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// products for the UI
  var products = <ProductModel>[].obs;

  /// keep ALL image urls per product id (exactly as in Firestore)
  final Map<int, List<String>> imageUrlsById = {};

  Future<void> fetchProducts(String categoryName) async {
    try {
      final snap = await _firestore
          .collection('inventory')
          .doc(categoryName)
          .collection('items')
          .get();

      final mapped = snap.docs.map((doc) {
        final product = _mapDocToProduct(doc);

        // keep the full list AS-IS (no filtering)
        final data = doc.data();
        final rawList = data['imageUrls'];
        final allImages = (rawList is List)
            ? rawList.map((e) => e.toString()).toList()
            : <String>[];

        imageUrlsById[product.id] = allImages;

        return product;
      }).toList();

      products.assignAll(mapped);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products');
    }
  }

  ProductModel _mapDocToProduct(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    String pickImage(Map<String, dynamic> d) {
      final rawList = d['imageUrls'];
      if (rawList is List && rawList.isNotEmpty) {
        for (final v in rawList) {
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
      final alt = (d['image'] ?? d['imageUrl'] ?? '').toString().trim();
      return alt;
    }

    final name = (data['Name'] ?? data['name'] ?? '').toString();
    final description =
        (data['Description'] ?? data['description'] ?? '').toString();
    final quantity = _asInt(data['quantity']) ?? 0;
    final price = _asDouble(data['price']) ?? 0.0;
    final id = _asInt(data['id']) ?? _hashId(doc.id);

    return ProductModel(
      id: id,
      image: pickImage(data),
      name: name,
      description: description,
      quantity: quantity,
      price: price,
    );
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(s);
  }

  int _hashId(String s) => s.hashCode;
}
