import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:grocerygo/Screens/admin_order_page.dart';
import 'package:grocerygo/Screens/admin_upload_csv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:grocerygo/Screens/admin_category_page.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Widget> _pages = [];
  List<String> _categories = []; // List to hold category names (document IDs)
  String? _selectedCategory; // Variable to hold the selected category

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories from Firestore on initialization
    _pages.add(_buildInventoryPage());
    _pages.add(AdminUploadCSVPage());
    _pages.add(AdminOrderPage());
    _pages.add(AdminCategoryScreen());
  }

  void _fetchCategories() async {
    // Fetch categories from Firestore (assuming each category is a document ID)
    QuerySnapshot snapshot = await _firestore.collection('inventory').get();
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
                  onChanged: (value) {
                    itemName = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Price'),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    price = value;
                  },
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
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
                  foregroundColor: Colors.white),
              onPressed: () async {
                if (itemName.isNotEmpty &&
                    price.isNotEmpty &&
                    image != null &&
                    _selectedCategory != null) {
                  String imageUrl = await _uploadImageToStorage(image!);

                  // Add item under the selected category
                  await _firestore
                      .collection('inventory')
                      .doc(_selectedCategory)
                      .collection('items')
                      .add({
                    'name': itemName,
                    'price': price,
                    'stock': stock,
                    'imageUrl': imageUrl,
                    'count': 1, // Default count when adding
                  });

                  Navigator.of(context).pop();
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
                  onChanged: (value) {
                    itemName = value;
                  },
                ),
                TextField(
                  decoration: const InputDecoration(hintText: 'Price'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: price),
                  onChanged: (value) {
                    price = value;
                  },
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
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
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              onPressed: () async {
                await _firestore
                    .collection('inventory')
                    .doc(category)
                    .collection('items')
                    .doc(doc.id)
                    .delete();
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                  foregroundColor: Colors.white),
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

                Navigator.of(context).pop();
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
          return const Center(
            child: Text('No categories available'),
          );
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
                      return const Center(
                        child: Text('No items in this category'),
                      );
                    }

                    return Column(
                      children: itemSnapshot.data!.docs.map((itemDoc) {
                        return Card(
                          child: ListTile(
                            leading: Image.network(itemDoc['imageUrl']),
                            title: Text(itemDoc['name']),
                            subtitle: Text('Price: ${itemDoc['price']}'),
                            trailing: Text(
                                itemDoc['stock'] ? 'In Stock' : 'Out of Stock'),
                            onTap: () => _editItemDialog(itemDoc,
                                categoryDoc.id), // Tap to edit the item
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
        items: const <BottomNavigationBarItem>[
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
              icon: Icon(Icons.category), label: 'Categories'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurple, // Customize selected item color
        unselectedItemColor: Colors.grey, // Customize unselected item color
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
