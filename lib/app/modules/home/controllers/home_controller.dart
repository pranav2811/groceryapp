import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/theme/my_theme.dart';
import '../../../../utils/constants.dart';
import '../../../data/local/my_shared_pref.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../../utils/dummy_helper.dart';

/// Internal helper to keep track of category along with product
class _ProductWithCategory {
  final ProductModel product;
  final String category;
  _ProductWithCategory(this.product, this.category);
}

class HomeController extends GetxController {
  // Categories
  List<CategoryModel> categories = [];

  // Best-selling products fetched from Firestore
  List<ProductModel> bestSelling = [];
  bool isLoadingBestSelling = true;

  // Search state
  bool isSearching = false;
  String _lastQuery = '';
  List<ProductModel> searchResults = [];
  Timer? _debounce; // for onChanged debounce

  // Theme
  var isLightTheme = MySharedPref.getThemeIsLight();

  // Cards
  var cards = [Constants.card1, Constants.card2, Constants.card3];

  @override
  void onInit() {
    getCategories();

    // Wait for auth before querying (satisfy security rules)
    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (user != null) {
        fetchBestSelling(); // default count=8, poolSize=50, maxPerCategory=2
      } else {
        isLoadingBestSelling = false;
        update(['BestSelling']);
      }
    });

    super.onInit();
  }

  void getCategories() {
    categories = DummyHelper.categories;
  }

  /// Fetch a random-ish set of products from collectionGroup('items').
  /// Enforces a per-category cap (maxPerCategory) for variety.
  Future<void> fetchBestSelling({
    int count = 8,
    int poolSize = 50,
    int maxPerCategory = 2,
  }) async {
    try {
      isLoadingBestSelling = true;
      update(['BestSelling']);

      final snap = await FirebaseFirestore.instance
          .collectionGroup('items')
          .limit(poolSize)
          .get();

      // Map to (product, category)
      final pool = <_ProductWithCategory>[];
      for (final doc in snap.docs) {
        final product = _mapDocToProduct(doc);
        if (product == null) continue;

        final category = doc.reference.parent.parent?.id ?? 'uncategorized';
        pool.add(_ProductWithCategory(product, category));
      }

      // Shuffle, then pick with per-category cap
      pool.shuffle();
      final picked = <ProductModel>[];
      final perCatCount = <String, int>{};

      for (final it in pool) {
        if (picked.length >= count) break;
        final used = perCatCount[it.category] ?? 0;
        if (used >= maxPerCategory) continue;

        picked.add(it.product);
        perCatCount[it.category] = used + 1;
      }

      bestSelling = picked;
    } catch (e) {
      Get.log('Failed to load best selling: $e');
      bestSelling = [];
    } finally {
      isLoadingBestSelling = false;
      update(['BestSelling']);
    }
  }

  /// Public API from the view: debounce text changes to avoid spamming queries.
  void onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      runSearch(text);
    });
  }

  /// Public API: handle keyboard "Search" action immediately.
  Future<void> onSearchSubmitted(String text) => runSearch(text);

  /// Clear current search and show the normal home content again.
  void clearSearch() {
    _lastQuery = '';
    isSearching = false;
    searchResults = [];
    update(['Search']);
  }

  /// Core search logic.
  /// Fast path: prefix search on 'nameLower' field (recommended to store per item).
  /// Fallback: fetch a pool and filter client-side by substring.
  Future<void> runSearch(String query,
      {int limit = 24, int poolSize = 200}) async {
    final q = query.trim();
    _lastQuery = q;

    if (q.isEmpty) {
      clearSearch();
      return;
    }

    isSearching = true;
    update(['Search']);

    final qLower = q.toLowerCase();

    try {
      // Try server-side prefix search using 'nameLower'
      final snap = await FirebaseFirestore.instance
          .collectionGroup('items')
          .orderBy('nameLower')
          .startAt([qLower])
          .endAt(['$qLower\uf8ff'])
          .limit(limit)
          .get();

      final mapped = snap.docs
          .map(_mapDocToProduct)
          .where((p) => p != null)
          .cast<ProductModel>()
          .toList();

      // If nothing came back (or nameLower not present), fallback below.
      if (mapped.isNotEmpty) {
        searchResults = mapped;
        update(['Search']);
        return;
      }
    } catch (e) {
      // Probably missing index/field; we'll fallback.
      Get.log('Search fast-path failed (likely missing nameLower index): $e');
    }

    // Fallback: client-side filter over a larger pool
    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('items')
          .limit(poolSize)
          .get();

      final pool = snap.docs
          .map(_mapDocToProduct)
          .where((p) => p != null)
          .cast<ProductModel>()
          .toList();

      searchResults = pool
          .where((p) => p.name.toLowerCase().contains(qLower))
          .take(limit)
          .toList();
    } catch (e) {
      Get.log('Search fallback failed: $e');
      searchResults = [];
    }

    update(['Search']);
  }

  /// Map Firestore doc → ProductModel (aligns with your current fields)
  ProductModel? _mapDocToProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    // Name (required)
    final name = (data['name'] ?? data['title'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    // ID (int) — prefer explicit numeric 'id'; else try parse; else derive
    final int id = _extractIntId(data, doc.id);

    // Description
    final description =
        (data['description'] ?? data['desc'] ?? '').toString();

    // Image: prefer first non-empty from imageUrls[], else 'image'/'imageUrl'
    String image = '';
    final rawList = data['imageUrls'];
    if (rawList is List) {
      image = rawList
          .map((e) => (e ?? '').toString())
          .firstWhere((u) => u.isNotEmpty, orElse: () => '');
    }
    if (image.isEmpty) {
      image = (data['image'] ?? data['imageUrl'] ?? '').toString();
    }

    // Quantity (optional → default 0)
    int quantity = 0;
    final rawQty = data['quantity'];
    if (rawQty is num) quantity = rawQty.toInt();
    if (rawQty is String) quantity = int.tryParse(rawQty) ?? 0;

    // Price (double)
    double price = 0.0;
    final rawPrice = data['price'];
    if (rawPrice is num) price = rawPrice.toDouble();
    if (rawPrice is String) price = double.tryParse(rawPrice) ?? 0.0;

    return ProductModel(
      id: id,
      image: image,
      name: name,
      description: description,
      quantity: quantity,
      price: price,
    );
  }

  /// Best-effort extraction of an integer ID.
  int _extractIntId(Map<String, dynamic> data, String docId) {
    final v = data['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    // Fallback: derive from docId (hashCode is sufficient for UI identity).
    return docId.hashCode;
  }

  /// Theme toggle
  void onChangeThemePressed() {
    MyTheme.changeTheme();
    isLightTheme = MySharedPref.getThemeIsLight();
    update(['Theme']);
  }
}
