// class Product {
//   final String name;
//   final String picPath;
//   final String weight;
//   final String description;
//   final String price;
//   int orderedQuantity;

//   Product({
//     this.name = 'null',
//     this.picPath = 'null',
//     this.weight = 'null',
//     this.description =
//         '''This is a professional description, so that you can buy our overpriced product, go home an be happy!''',
//     this.price = 'null',
//     this.orderedQuantity = 1,
//   });

//   void makeOrder({int bulkOrder = 0}) {
//     if (bulkOrder == 0) {
//       orderedQuantity++;
//       return;
//     }
//     orderedQuantity += bulkOrder;
//   }
// }
class Product {
  final String name;
  final String picPath;
  final String weight;
  final String description;
  final String price;
  int orderedQuantity;

  Product({
    this.name = 'null',
    this.picPath =
        'https://via.placeholder.com/150', // Default image if not provided
    this.weight = '1kg', // Default weight if not provided
    this.description =
        'This is a professional description, so that you can buy our overpriced product, go home and be happy!',
    this.price = '0',
    this.orderedQuantity = 1,
  });

  /// Factory constructor to create a Product from Firestore document data
  factory Product.fromMap(Map<String, dynamic> data) {
    return Product(
      name: data['name'] ?? 'Unnamed Product',
      picPath: data['imageUrl'] ?? 'https://via.placeholder.com/150',
      weight: data['weight'] ?? '1kg',
      description: data['description'] ??
          'This is a professional description, so that you can buy our overpriced product, go home and be happy!',
      price: data['price'] ?? '0',
      orderedQuantity: data['orderedQuantity'] ?? 1,
    );
  }

  /// Method to make an order, with an optional bulk order quantity
  void makeOrder({int bulkOrder = 0}) {
    if (bulkOrder == 0) {
      orderedQuantity++;
      return;
    }
    orderedQuantity += bulkOrder;
  }
}
