import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../config/theme/my_theme.dart';
import '../../../data/local/my_shared_pref.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../../utils/dummy_helper.dart';

class _ProductWithCategory {
  final ProductModel product;
  final String category;
  _ProductWithCategory(this.product, this.category);
}

class HomeController extends GetxController {
  // Categories
  List<CategoryModel> categories = [];

  // Best-selling
  List<ProductModel> bestSelling = [];
  bool isLoadingBestSelling = true;

  // Search
  bool isSearching = false;
  String _lastQuery = '';
  List<ProductModel> searchResults = [];
  Timer? _debounce;

  // Theme
  var isLightTheme = MySharedPref.getThemeIsLight();

  // Offer images from Firestore
  List<String> offerImages = [];

  @override
  void onInit() {
    getCategories();
    _listenOffers();

    FirebaseAuth.instance.authStateChanges().first.then((user) {
      if (user != null) {
        fetchBestSelling();
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

  void _listenOffers() {
    FirebaseFirestore.instance
        .collection('offers')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snap) {
      final imgs = <String>[];
      for (final d in snap.docs) {
        final data = d.data();
        final url = (data['imageUrl'] ?? '').toString().trim();
        if (url.isNotEmpty) {
          imgs.add(url);
        }
      }
      offerImages = imgs;
      update(['Search']); // same GetBuilder used for carousel
    });
  }

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

      final pool = <_ProductWithCategory>[];
      for (final doc in snap.docs) {
        final product = _mapDocToProduct(doc);
        if (product == null) continue;
        final category = doc.reference.parent.parent?.id ?? 'uncategorized';
        pool.add(_ProductWithCategory(product, category));
      }

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

  // -------------------- Search --------------------

  void onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      onSearchSubmitted(text);
    });
  }

  Future<void> onSearchSubmitted(String text) async {
    _debounce?.cancel();
    await runSearch(text);
  }

  void clearSearch() {
    _lastQuery = '';
    isSearching = false;
    searchResults = [];
    update(['Search']);
  }

  Future<void> runSearch(String query,
      {int limit = 24, int poolSize = 200}) async {
    final q = query.trim();
    if (q.isEmpty) {
      clearSearch();
      return;
    }

    if (q == _lastQuery && searchResults.isNotEmpty) {
      isSearching = true;
      update(['Search']);
      return;
    }
    _lastQuery = q;
    isSearching = true;
    update(['Search']);

    final qLower = q.toLowerCase();

    List<ProductModel> mapAndDedupe(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) {
      final seenPaths = <String>{};
      final seenKeys = <String>{};
      final results = <ProductModel>[];

      for (final d in docs) {
        final path = d.reference.path;
        if (!seenPaths.add(path)) continue;

        final data = d.data();
        final nameLower = (data['nameLower'] ?? data['name'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        if (nameLower.isEmpty) continue;

        final category = d.reference.parent.parent?.id ?? 'uncategorized';
        final key = '$nameLower::$category';
        if (!seenKeys.add(key)) continue;

        final p = _mapDocToProduct(d);
        if (p != null) results.add(p);
      }
      return results;
    }

    // fast path
    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('items')
          .orderBy('nameLower')
          .startAt([qLower])
          .endAt(['$qLower\uf8ff'])
          .limit(limit * 3)
          .get();

      final mapped = mapAndDedupe(snap.docs);
      if (mapped.isNotEmpty) {
        searchResults = mapped.take(limit).toList();
        update(['Search']);
        return;
      }
    } catch (e) {
      Get.log('Search fast-path failed: $e');
    }

    // fallback
    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('items')
          .limit(poolSize)
          .get();

      final pool = mapAndDedupe(snap.docs);
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

  // -------------------- Mapping helpers --------------------

  ProductModel? _mapDocToProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final name = (data['name'] ?? data['title'] ?? '').toString().trim();
    if (name.isEmpty) return null;

    final int id = _extractIntId(data, doc.id);

    final description = (data['description'] ?? data['desc'] ?? '').toString();

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

    int quantity = 0;
    final rawQty = data['quantity'];
    if (rawQty is num) quantity = rawQty.toInt();
    if (rawQty is String) quantity = int.tryParse(rawQty) ?? 0;

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

  int _extractIntId(Map<String, dynamic> data, String docId) {
    final v = data['id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final parsed = int.tryParse(v);
      if (parsed != null) return parsed;
    }
    return docId.hashCode;
  }

  // -------------------- Theme toggle --------------------

  void onChangeThemePressed() {
    MyTheme.changeTheme();
    isLightTheme = MySharedPref.getThemeIsLight();
    update(['Theme']);
  }
}
