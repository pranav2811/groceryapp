import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Category {
  final String name;
  final String imageUrl;

  Category({required this.name, required this.imageUrl});
}

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var categories = <Category>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final categoryDocs = await _firestore.collection('inventory').get();
      final List<Future<Category>> tasks = [];

      for (final categoryDoc in categoryDocs.docs) {
        tasks.add(_buildCategoryFromDoc(categoryDoc));
      }

      final results = await Future.wait(tasks);
      results.sort((a, b) => a.name.compareTo(b.name));
      categories.assignAll(results);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories: $e');
    }
  }

  Future<Category> _buildCategoryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> categoryDoc,
  ) async {
    final data = categoryDoc.data();
    final String categoryName = categoryDoc.id;

    // 1) prefer category-level image
    String imageUrl = _firstValidUrl(data['imageUrl'] ?? data['imageUrls']);

    // 2) fallback: look into items
    if (imageUrl.isEmpty) {
      final itemsSnapshot = await _firestore
          .collection('inventory')
          .doc(categoryName)
          .collection('items')
          .limit(10)
          .get();

      for (final itemDoc in itemsSnapshot.docs) {
        final item = itemDoc.data();
        final candidate = _firstValidUrl(item['imageUrl'] ?? item['imageUrls']);
        if (candidate.isNotEmpty) {
          imageUrl = candidate;
          break;
        }
      }
    }

    return Category(name: categoryName, imageUrl: imageUrl);
  }

  /// returns first good url; for lists, try to SKIP index 0 (disclaimer)
  String _firstValidUrl(dynamic value) {
    const blacklist = [
      'disclaimer',
      'placeholder',
      'no_image',
      'noimage',
      'watermark',
    ];

    bool looksLikeUrl(String s) {
      final u = s.trim();
      if (u.isEmpty) return false;
      final lower = u.toLowerCase();
      return lower.startsWith('http://') ||
          lower.startsWith('https://') ||
          lower.startsWith('gs://') ||
          lower.contains('firebasestorage.googleapis.com');
    }

    bool isBlacklisted(String s) {
      final lower = s.toLowerCase();
      for (final bad in blacklist) {
        if (lower.contains(bad)) return true;
      }
      return false;
    }

    bool ok(String s) => looksLikeUrl(s) && !isBlacklisted(s);

    // single string
    if (value is String) {
      final v = value.trim();
      return ok(v) ? v : '';
    }

    // list of strings
    if (value is List) {
      // normalize
      final urls = value.map((e) => e?.toString().trim() ?? '').toList();

      // 1) try AFTER the first
      if (urls.length > 1) {
        for (var i = 1; i < urls.length; i++) {
          final v = urls[i];
          if (ok(v)) return v;
        }
      }

      // 2) fall back to first
      if (urls.isNotEmpty && ok(urls.first)) {
        return urls.first;
      }
    }

    return '';
  }
}
