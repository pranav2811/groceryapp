
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class Category {
  final String name;
  final String imageUrl;

  Category({required this.name, required this.imageUrl});
}

class CategoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var categories = <Category>[].obs; // Observable list of categories

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

  /// Build a Category from a category doc:
  /// 1) Prefer category-level imageUrl (string or list)
  /// 2) Else scan items subcollection for first usable image URL
  Future<Category> _buildCategoryFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> categoryDoc,
  ) async {
    final data = categoryDoc.data();
    final String categoryName = categoryDoc.id;

    // Try category-level image first (supports string or list)
    String imageUrl = _firstValidUrl(data['imageUrl'] ?? data['imageUrls']);

    // Fallback: scan a few items for the first usable URL
    if (imageUrl.isEmpty) {
      final itemsSnapshot = await _firestore
          .collection('inventory')
          .doc(categoryName)
          .collection('items')
          .limit(10) // scan a handful; adjust if needed
          .get();

      for (final itemDoc in itemsSnapshot.docs) {
        final item = itemDoc.data();
        final String candidate =
            _firstValidUrl(item['imageUrl'] ?? item['imageUrls']);
        if (candidate.isNotEmpty) {
          imageUrl = candidate;
          break;
        }
      }
    }

    return Category(name: categoryName, imageUrl: imageUrl);
  }

  /// Returns the first *valid* URL from either:
  /// - a single String, or
  /// - a List<String> (e.g., imageUrl:[...], imageUrls:[...])
  ///
  /// Skips:
  /// - empty strings
  /// - obvious placeholders/boilerplates (blacklist substrings)
  /// - strings that don't look like URLs
  String _firstValidUrl(dynamic value) {
    // Add substrings you want to skip (case-insensitive)
    const List<String> blacklistSubstrings = [
      'disclaimer',
      'placeholder',
      'no_image',
      'noimage',
      'watermark',
    ];

    bool looksLikeUrl(String s) {
      final u = s.trim();
      if (u.isEmpty) return false;
      // Basic URL check; extend as needed (e.g., allow gs://, firebase storage URLs)
      final lower = u.toLowerCase();
      final isHttp = lower.startsWith('http://') || lower.startsWith('https://');
      final isGs = lower.startsWith('gs://');
      final isStorageApi = lower.contains('firebasestorage.googleapis.com');
      return isHttp || isGs || isStorageApi;
    }

    bool isBlacklisted(String s) {
      final lower = s.toLowerCase();
      for (final bad in blacklistSubstrings) {
        if (lower.contains(bad)) return true;
      }
      return false;
    }

    bool isValid(String s) => looksLikeUrl(s) && !isBlacklisted(s);

    if (value is String) {
      final v = value.trim();
      return isValid(v) ? v : '';
    }

    if (value is List) {
      for (final e in value) {
        if (e is String) {
          final v = e.trim();
          if (isValid(v)) return v;
        }
      }
    }

    return '';
  }
}
