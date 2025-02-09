// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// class Category {
//   final String name;
//   final String imageUrl;

//   Category({required this.name, required this.imageUrl});
// }

// class CategoryController extends GetxController {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   var categories = <Category>[].obs; // Observable list of categories

//   @override
//   void onInit() {
//     super.onInit();
//     fetchCategories();
//   }

//   Future<void> fetchCategories() async {
//     try {
//       final categoryDocs = await _firestore.collection('inventory').get();
//       final List<Category> fetchedCategories = [];

//       for (var categoryDoc in categoryDocs.docs) {
//         String categoryName = categoryDoc.id;

//         // Get any item in this category to retrieve its image URL
//         final itemsSnapshot = await _firestore
//             .collection('inventory')
//             .doc(categoryName)
//             .collection('items')
//             .limit(1) // Limit to one item
//             .get();

//         String imageUrl = itemsSnapshot.docs.isNotEmpty
//             ? itemsSnapshot.docs.first['imageUrl']
//             : 'https://via.placeholder.com/150'; // Placeholder if no image

//         fetchedCategories.add(Category(name: categoryName, imageUrl: imageUrl));
//       }

//       fetchedCategories.sort((a, b) => a.name.compareTo(b.name));

//       categories.assignAll(fetchedCategories);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load categories');
//     }
//   }
// }
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
      final List<Category> fetchedCategories = [];

      for (var categoryDoc in categoryDocs.docs) {
        String categoryName = categoryDoc.id;

        // Get any item in this category to retrieve its image URL
        String imageUrl =
            'https://via.placeholder.com/150'; // Default placeholder

        final itemsSnapshot = await _firestore
            .collection('inventory')
            .doc(categoryName)
            .collection('items')
            .limit(1)
            .get();

        if (itemsSnapshot.docs.isNotEmpty) {
          imageUrl = itemsSnapshot.docs.first.data()['imageUrl'] ?? imageUrl;
        }

        fetchedCategories.add(Category(name: categoryName, imageUrl: imageUrl));
      }

      fetchedCategories.sort((a, b) => a.name.compareTo(b.name));
      categories.assignAll(fetchedCategories);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load categories: $e');
    }
  }
}
