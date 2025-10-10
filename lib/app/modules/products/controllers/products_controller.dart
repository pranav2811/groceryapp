import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:groceryapp/app/data/models/product_model.dart';

class ProductsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var products = <ProductModel>[].obs;

  Future<void> fetchProducts(String categoryName) async {
    try {
      final snap = await _firestore
          .collection('inventory')
          .doc(categoryName)
          .collection('items')
          .get();

      final mapped = snap.docs.map(_mapDocToProduct).toList();
      products.assignAll(mapped);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load products');
    }
  }

  /// Map one Firestore document to your ProductModel
  ProductModel _mapDocToProduct(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // 1) Image: pick first non-empty from imageUrls, else fallback to 'image'/'imageUrl'
    String _pickImage(Map<String, dynamic> d) {
      final rawList = d['imageUrls'];
      if (rawList is List && rawList.isNotEmpty) {
        // take first non-empty string
        for (final v in rawList) {
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
      }
      final alt = (d['image'] ?? d['imageUrl'] ?? '').toString().trim();
      return alt; // could be '' if none present
    }

    // 2) Name / Description (note Firestore uses capitalized keys in your screenshot)
    final name = (data['Name'] ?? data['name'] ?? '').toString();
    final description = (data['Description'] ?? data['description'] ?? '').toString();

    // 3) Quantity (default 0 if absent)
    final quantity = _asInt(data['quantity']) ?? 0;

    // 4) Price (default 0.0 if absent)
    final price = _asDouble(data['price']) ?? 0.0;

    // 5) ID: use doc.id if no numeric id is stored
    final id = _asInt(data['id']) ?? _hashId(doc.id);

    return ProductModel(
      id: id,
      image: _pickImage(data),
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
    // strip any trailing currency like "$" if present
    final s = v.toString().replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(s);
  }

  // simple stable hash of Firestore string id to make an int (only if you need an int id)
  int _hashId(String s) => s.hashCode;
}
