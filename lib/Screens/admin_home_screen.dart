import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:grocerygo/Screens/admin_order_page.dart';
import 'package:image_picker/image_picker.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Define the list of pages; index 0 is now the inventory page itself.
  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(_buildInventoryPage()); // Setting the inventory page at index 0
    _pages.add(AdminOrderPage()); // Placeholder for orders or other admin pages
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  image = await picker.pickImage(source: ImageSource.gallery);
                },
                child: const Text('Upload Image'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (itemName.isNotEmpty && price.isNotEmpty && image != null) {
                  String imageUrl = await _uploadImageToStorage(image!);

                  await _firestore.collection('inventory').add({
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
    // Assuming you have Firebase Storage setup
    // Upload the image to Firebase Storage and get the URL
    final ref = FirebaseStorage.instance.ref().child('items/${image.name}');
    await ref.putFile(File(image.path));
    return await ref.getDownloadURL();
  }

  // Build the inventory page as a separate method
  Widget _buildInventoryPage() {
    return StreamBuilder(
      stream: _firestore.collection('inventory').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No items available'),
          );
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return Card(
              child: ListTile(
                leading: Image.network(doc['imageUrl']),
                title: Text(doc['name']),
                subtitle: Text('Price: ${doc['price']}'),
                trailing: Text(doc['stock'] ? 'In Stock' : 'Out of Stock'),
              ),
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
      body: _pages[_selectedIndex], // Show the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Orders',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton:
          _selectedIndex == 0 // Only show FAB on the Inventory page
              ? FloatingActionButton(
                  onPressed: _addItemDialog,
                  child: const Icon(Icons.add),
                )
              : null, // No FAB for other tabs
    );
  }
}
