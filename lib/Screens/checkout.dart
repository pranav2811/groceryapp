import 'package:flutter/material.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  List<CartItem> cartItems = [
    CartItem(
      name: 'Apple',
      price: 1.5,
      quantity: 2,
      imageUrl: 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce',
    ),
    CartItem(
      name: 'Bread',
      price: 2.0,
      quantity: 1,
      imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e',
    ),
  ];

  List<String> addresses = [
    '123 Main Street',
    '456 Maple Avenue',
    '789 Oak Lane',
  ];
  String selectedAddress = '';

  List<String> paymentMethods = [
    'Credit Card',
    'Debit Card',
    'UPI',
    'Cash on Delivery',
  ];
  String selectedPaymentMethod = '';

  @override
  void initState() {
    super.initState();
    selectedAddress = addresses[0];
    selectedPaymentMethod = paymentMethods[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCartItemsSection(),
                const Divider(thickness: 1.5),
                _buildAddressSelectionSection(),
                const Divider(thickness: 1.5),
                _buildPaymentMethodSection(),
              ],
            ),
          ),
          _buildPayNowButton(),
        ],
      ),
    );
  }

  Widget _buildCartItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Your Cart'),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartItems.length,
          itemBuilder: (context, index) {
            return _buildCartItem(cartItems[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error, color: Colors.red),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            _buildQuantityControl(item),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControl(CartItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              if (item.quantity > 1) item.quantity--;
            });
          },
        ),
        Text(
          '${item.quantity}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          onPressed: () {
            setState(() {
              item.quantity++;
            });
          },
        ),
      ],
    );
  }

  Widget _buildAddressSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Delivery Address'),
        const SizedBox(height: 10),
        ...addresses.map((address) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: RadioListTile(
              activeColor: Colors.blueAccent,
              title: Text(address),
              value: address,
              groupValue: selectedAddress,
              onChanged: (value) {
                setState(() {
                  selectedAddress = value!;
                });
              },
            ),
          );
        }),
        TextButton(
          onPressed: () {
            // Add new address
          },
          child: const Text('+ Add New Address'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Payment Method'),
        const SizedBox(height: 10),
        ...paymentMethods.map((method) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: RadioListTile(
              activeColor: Colors.blueAccent,
              title: Text(method),
              value: method,
              groupValue: selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                });
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPayNowButton() {
    double totalAmount = cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          // Process payment
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Pay Now - \$${totalAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class CartItem {
  String name;
  double price;
  int quantity;
  String imageUrl;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });
}
