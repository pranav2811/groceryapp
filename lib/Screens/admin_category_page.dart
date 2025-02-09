import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminCategoryScreen extends StatefulWidget {
  const AdminCategoryScreen({super.key});

  @override
  State<AdminCategoryScreen> createState() => _AdminCategoryScreenState();
}

class _AdminCategoryScreenState extends State<AdminCategoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String categoryName = '';

  Future<void> _addCategoryDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            decoration: const InputDecoration(hintText: 'Category Name'),
            onChanged: (value) {
              categoryName = value;
            },
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 222, 186, 248),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (categoryName.isNotEmpty) {
                  await _firestore
                      .collection('inventory')
                      .doc(categoryName)
                      .set({}); // Create a new document with the category name
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Category'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCategory(String categoryId) async {
    await _firestore.collection('inventory').doc(categoryId).delete();
  }

  Widget _buildCategoryList() {
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
          children: snapshot.data!.docs.map((doc) {
            return Card(
              child: ListTile(
                title: Text(doc.id),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _deleteCategory(doc.id);
                  },
                ),
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
        title: const Text('Admin Category Screen'),
      ),
      body: _buildCategoryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
