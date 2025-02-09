import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class UpiPaymentPage extends StatefulWidget {
  const UpiPaymentPage({super.key});

  @override
  _UpiPaymentPageState createState() => _UpiPaymentPageState();
}

class _UpiPaymentPageState extends State<UpiPaymentPage> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _initiatePayment();
  }

  void _initiatePayment() {
    var options = {
      'key': 'YOUR_RAZORPAY_API_KEY',
      'amount': 100, // Amount in the smallest currency unit (100 paise = 1 INR)
      'currency': 'INR',
      'name': 'GroceryGo',
      'description': 'UPI Payment for your order',
      'prefill': {
        'contact': '9876543210',
        'email': 'example@gmail.com',
      },
      'theme': {'color': '#3399cc'}
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print(e.toString());
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Update order status in Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Payment successful! Order ID: ${response.orderId}')),
    );
    Navigator.pop(context, 'UPI Payment Successful');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed. Please try again.')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  @override
  void dispose() {
    _razorpay.clear(); // Removes all listeners
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('UPI Payment'),
      ),
      body: Center(
        child: Text('Processing your payment...'),
      ),
    );
  }
}
