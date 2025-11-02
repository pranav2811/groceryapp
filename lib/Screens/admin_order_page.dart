import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminOrderPage extends StatefulWidget {
  const AdminOrderPage({super.key});

  @override
  State<AdminOrderPage> createState() => _AdminOrderPageState();
}

class _AdminOrderPageState extends State<AdminOrderPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------- Normalizers & formatters ----------------

  Map<String, dynamic> _normalizeAddress(dynamic raw) {
    if (raw == null) return {};
    if (raw is Map && raw['address'] is Map) {
      raw = raw['address'];
    }
    if (raw is! Map) return {};
    final m = Map<String, dynamic>.from(raw);

    const junkKeys = {
      'paymentMethod',
      'status',
      'timestamp',
      'imageUrl',
      'type',
      'userId',
      'userName',
      'items',
      'id',
    };
    m.removeWhere((k, v) => junkKeys.contains(k));
    return m;
  }

  /// Pretty string for ONLY the address lines (no name/phone).
  String _addressOnlyPretty(Map<String, dynamic> m) {
    if (m.isEmpty) return 'No address';

    final parts = [
      m['flatHouseFloorBuilding'] ?? m['flat'] ?? m['line1'],
      m['areaSectorLocality'] ?? m['area'] ?? m['line2'],
      m['nearbyLandmark'] ?? m['landmark'],
      m['city'],
      m['state'],
      m['pincode'] ?? m['zip'],
      m['country'],
    ]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim())
        .toList();

    return parts.isEmpty ? 'No address' : parts.join(', ');
  }

  /// Extracts name & phone (if present) from address map (handles nested).
  ({String name, String phone}) _extractNamePhone(dynamic raw) {
    Map<String, dynamic> m = _normalizeAddress(raw);
    final name = (m['name'] ?? '').toString().trim();
    final phone = (m['phone'] ?? '').toString().trim();
    return (name: name, phone: phone);
  }

  /// Extract payment method whether top-level or nested under address.paymentMethod
  String _extractPaymentMethod(Map<String, dynamic> docData) {
    final fromTop = (docData['paymentMethod'] ?? '').toString().trim();
    if (fromTop.isNotEmpty) return fromTop;
    final addr = docData['address'];
    if (addr is Map) {
      final nested = (addr['paymentMethod'] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
    }
    return '—';
  }

  // ---------------- Actions ----------------

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order $orderId updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _updatePhotoOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore
          .collection('photo_orders')
          .doc(orderId)
          .update({'status': newStatus});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo order $orderId updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _rejectPhotoOrder(String orderId, String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }
      await _firestore.collection('photo_orders').doc(orderId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo order rejected and deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject photo order: $e')),
      );
    }
  }

  // -------- Fullscreen image viewer --------
  void _openImageViewer(String imageUrl) {
    if (imageUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, widget, progress) {
                  if (progress == null) return widget;
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                },
                errorBuilder: (context, error, st) =>
                    const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Tabs content ----------------

  Widget _cartOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No standard cart orders.'),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final items = (data['items'] as List<dynamic>? ?? []);
            final addressMap = _normalizeAddress(data['address']);
            final addrPretty = _addressOnlyPretty(addressMap);
            final np = _extractNamePhone(data['address']);
            final status = (data['status'] ?? 'pending').toString();
            final paymentMethod = _extractPaymentMethod(data);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ExpansionTile(
                title: Text('Order ID: ${doc.id}'),
                subtitle: Text('Status: $status'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Items:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...items.map((item) {
                          final it = (item as Map<String, dynamic>);
                          final itemName = it['name'] ?? 'Item';
                          final itemPrice = it['price'] ?? 0;
                          return Text('- $itemName: \₹$itemPrice');
                        }),
                        const SizedBox(height: 12),
                        const Text('Details:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Address: $addrPretty"),
                        if (np.name.isNotEmpty) Text('Name: ${np.name}'),
                        if (np.phone.isNotEmpty) Text('Phone: ${np.phone}'),
                        const SizedBox(height: 6),
                        Text('Payment: $paymentMethod'),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _updateOrderStatus(doc.id, 'delivered'),
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: const Text('Delivered'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _updateOrderStatus(doc.id, 'rejected'),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              label: const Text('Rejected'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _photoOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('photo_orders')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error loading photo orders: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No photo orders.'),
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;
            final status = (data['status'] ?? 'pending').toString();
            final imageUrl = (data['imageUrl'] ?? '').toString();
            final addressMap =
                _normalizeAddress(data['address'] as Map<String, dynamic>?);
            final addrPretty = _addressOnlyPretty(addressMap);
            final np = _extractNamePhone(data['address']);
            final userName =
                (data['userName'] ?? data['userId'] ?? '').toString();
            final ts = (data['timestamp'] as Timestamp?);
            final tsStr = ts != null ? ts.toDate().toString() : '—';
            final paymentMethod = _extractPaymentMethod(data);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ExpansionTile(
                leading: GestureDetector(
                  onTap: () => _openImageViewer(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.photo, size: 56)
                        : Image.network(
                            imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            loadingBuilder: (c, w, progress) {
                              if (progress == null) return w;
                              return const SizedBox(
                                width: 56,
                                height: 56,
                                child: Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)),
                              );
                            },
                            errorBuilder: (c, err, st) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey),
                          ),
                  ),
                ),
                title: Text('Photo Order ID: ${doc.id}'),
                subtitle: Text('Status: $status • User: $userName'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          Center(
                            child: GestureDetector(
                              onTap: () => _openImageViewer(imageUrl),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (c, w, progress) {
                                    if (progress == null) return w;
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (c, err, st) => const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Could not load image'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text('Timestamp: $tsStr'),
                        const SizedBox(height: 8),
                        const Text('Details:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            text: 'Address: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: addrPretty,
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        if (np.name.isNotEmpty)
                          Text.rich(
                            TextSpan(
                              text: 'Name: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: np.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        if (np.phone.isNotEmpty)
                          Text.rich(
                            TextSpan(
                              text: 'Phone: ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: np.phone,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.normal),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text.rich(
                          TextSpan(
                            text: 'Payment: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: paymentMethod,
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _updatePhotoOrderStatus(doc.id, 'delivered'),
                              icon:
                                  const Icon(Icons.check, color: Colors.white),
                              label: const Text('Delivered'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _rejectPhotoOrder(doc.id, imageUrl),
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.white),
                              label: const Text('Reject & Delete'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- Scaffold with Tabs ----------------
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Orders'),
          bottom: const TabBar(
            isScrollable: false,
            tabs: [
              Tab(text: 'Cart Orders', icon: Icon(Icons.shopping_cart)),
              Tab(text: 'Photo Orders', icon: Icon(Icons.camera_alt)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CartOrdersTabProxy(),
            _PhotoOrdersTabProxy(),
          ],
        ),
      ),
    );
  }
}

// Proxies so TabBarView can access the state methods
class _CartOrdersTabProxy extends StatelessWidget {
  const _CartOrdersTabProxy();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AdminOrderPageState>();
    return state?._cartOrdersTab() ?? const SizedBox.shrink();
  }
}

class _PhotoOrdersTabProxy extends StatelessWidget {
  const _PhotoOrdersTabProxy();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_AdminOrderPageState>();
    return state?._photoOrdersTab() ?? const SizedBox.shrink();
  }
}
