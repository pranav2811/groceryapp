import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  int _selectedIndex = 1;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.add(const Placeholder()); // Placeholder for inventory page
    _pages.add(_buildOrdersPage()); // Set the orders page at index 1
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await _firestore
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }

  // Build the orders page as a separate method
  Widget _buildOrdersPage() {
    return StreamBuilder(
      stream: _firestore
          .collection('orders')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No open orders available'));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return ExpansionTile(
              title: Text('Order ID: ${doc.id}'),
              subtitle: const Text('Status: Open'),
              children: [
                Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Items: ${doc['items']}'),
                        const SizedBox(height: 10),
                        Text('Address: ${doc['address']}'),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _updateOrderStatus(doc.id, 'accepted');
                              },
                              child: const Text('Accept Order'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _updateOrderStatus(doc.id, 'delivered');
                              },
                              child: const Text('Deliver Order'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
        title: const Text('Orders'),
      ),
      body: _pages[_selectedIndex], // Show the selected page
    );
  }
}
