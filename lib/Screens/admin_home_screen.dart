import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:groceryapp/Screens/admin_order_page.dart';
import 'package:groceryapp/Screens/admin_upload_csv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:groceryapp/Screens/admin_category_page.dart';
import 'package:groceryapp/Screens/admin_offer_upload_page.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late List<Widget> _pages;              // <— late, will be set in initState
  List<String> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    // build all pages here so length always == bottom nav length
    _pages = [
      _buildInventoryPage(),
      const AdminUploadCSVPage(),
      const AdminOrderPage(),
      const AdminCategoryScreen(),
      const AdminOfferUploadPage(),
    ];
  }

  void _fetchCategories() async {
    final snapshot = await _firestore.collection('inventory').get();
    setState(() {
      _categories = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _addItemDialog() async {
    String itemName = '';
    String price = '';
    bool stock = true;
    XFile? image;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(hintText: 'Select Category'),
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(hintText: 'Item Name'),
                  onChanged: (value) => itemName = value,
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => price = value,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('In Stock'),
                    Switch(
                      value: stock,
                      onChanged: (value) {
                        setState(() {
                          stock = value;
                        });
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    image = await picker.pickImage(source: ImageSource.gallery);
                  },
                  child: const Text('Upload Image'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (itemName.isNotEmpty &&
                    price.isNotEmpty &&
                    image != null &&
                    _selectedCategory != null) {
                  final imageUrl = await _uploadImageToStorage(image!);

                  await _firestore
                      .collection('inventory')
                      .doc(_selectedCategory)
                      .collection('items')
                      .add({
                    'name': itemName,
                    'price': price,
                    'stock': stock,
                    'imageUrl': imageUrl,
                    'count': 1,
                  });

                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<String> _uploadImageToStorage(XFile image) async {
    final ref = FirebaseStorage.instance.ref().child('items/${image.name}');
    await ref.putFile(File(image.path));
    return await ref.getDownloadURL();
  }

  Future<void> _editItemDialog(DocumentSnapshot doc, String category) async {
    String itemName = doc['name'];
    String price = doc['price'];
    bool stock = doc['stock'];
    XFile? image;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'Item Name'),
                  controller: TextEditingController(text: itemName),
                  onChanged: (value) => itemName = value,
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Price'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: price),
                  onChanged: (value) => price = value,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('In Stock'),
                    Switch(
                      value: stock,
                      onChanged: (value) {
                        setState(() {
                          stock = value;
                        });
                      },
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final picker = ImagePicker();
                    image = await picker.pickImage(source: ImageSource.gallery);
                  },
                  child: const Text('Upload New Image'),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await _firestore
                    .collection('inventory')
                    .doc(category)
                    .collection('items')
                    .doc(doc.id)
                    .delete();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String? imageUrl = doc['imageUrl'];
                if (image != null) {
                  imageUrl = await _uploadImageToStorage(image!);
                }

                await _firestore
                    .collection('inventory')
                    .doc(category)
                    .collection('items')
                    .doc(doc.id)
                    .update({
                  'name': itemName,
                  'price': price,
                  'stock': stock,
                  'imageUrl': imageUrl,
                });

                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInventoryPage() {
    return StreamBuilder(
      stream: _firestore.collection('inventory').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return ListView(
          children: snapshot.data!.docs.map((categoryDoc) {
            return ExpansionTile(
              title: Text(categoryDoc.id),
              children: [
                StreamBuilder(
                  stream: _firestore
                      .collection('inventory')
                      .doc(categoryDoc.id)
                      .collection('items')
                      .snapshots(),
                  builder:
                      (context, AsyncSnapshot<QuerySnapshot> itemSnapshot) {
                    if (!itemSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (itemSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No items in this category'));
                    }

                    return Column(
                      children: itemSnapshot.data!.docs.map((itemDoc) {
                        return Card(
                          child: ListTile(
                            leading: (() {
                              final data =
                                  itemDoc.data() as Map<String, dynamic>?;

                              if (data != null &&
                                  data.containsKey('imageUrls') &&
                                  (data['imageUrls'] as List).isNotEmpty) {
                                final imageList =
                                    List<String>.from(data['imageUrls']);
                                return SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CarouselSlider(
                                    options: CarouselOptions(
                                      height: 100.0,
                                      autoPlay: true,
                                      enlargeCenterPage: true,
                                      enableInfiniteScroll: false,
                                    ),
                                    items: imageList.map((url) {
                                      return Image.network(url,
                                          fit: BoxFit.cover);
                                    }).toList(),
                                  ),
                                );
                              } else {
                                return Image.asset(
                                  'assets/placeholder.jpg',
                                  width: 100,
                                  height: 100,
                                );
                              }
                            })(),
                            title: Text(
                              (itemDoc.data()
                                          as Map<String, dynamic>?)?['name'] ??
                                  'No Name',
                            ),
                            subtitle: Text(
                              'Price: ${(itemDoc.data() as Map<String, dynamic>?)?['price'] ?? 'N/A'}',
                            ),
                            trailing: Text(
                              ((itemDoc.data()
                                              as Map<String, dynamic>?)?['stock'] ??
                                      false)
                                  ? 'In Stock'
                                  : 'Out of Stock',
                            ),
                            onTap: () =>
                                _editItemDialog(itemDoc, categoryDoc.id),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home Screen'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'CSV Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_offer),
            label: 'Offers',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _addItemDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
