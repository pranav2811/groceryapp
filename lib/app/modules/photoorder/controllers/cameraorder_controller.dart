// cameraorder_controller.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:groceryapp/widgets/add_address_bottom_sheet.dart';

class CameraViewController extends GetxController {
  late CameraController cameraController;
  List<CameraDescription> cameras = [];
  var isCameraInitialized = false.obs;
  var capturedImagePath = ''.obs;
  final isPlacingOrder = false.obs;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void onInit() async {
    super.onInit();
    await initCamera();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(cameras[0], ResolutionPreset.high);
      await cameraController.initialize();
      isCameraInitialized.value = true;
    }
  }

  Future<void> placeOrder(BuildContext context) async {
    if (capturedImagePath.value.isEmpty) {
      Get.snackbar('Missing photo', 'Please capture a photo first.');
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      Get.snackbar('Not logged in', 'Please sign in to place an order.');
      return;
    }

    // Confirm
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Place this order with the selected photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    // Pick / add address
    final address = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAddressBottomSheet(userId: user.uid),
    );
    if (address == null) return;

    try {
      isPlacingOrder.value = true;

      // Upload
      final file = File(capturedImagePath.value);
      final ext = p.extension(file.path);
      final name = 'photo_order_${user.uid}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final ref = _storage.ref().child('photo_orders/$name');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      // Save order
      await _firestore.collection('photo_orders').add({
        'userId': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'address': address,
        'imageUrl': url,
        'status': 'pending',
        'type': 'photo_order',
      });

      capturedImagePath.value = '';
      // Success dialog
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order Placed'),
          content: const Text('Your photo order has been placed successfully!'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      // Optionally navigate to orders screen:
      // Get.offNamed('/orders');
    } catch (e) {
      Get.snackbar('Order failed', e.toString());
    } finally {
      isPlacingOrder.value = false;
    }
  }

  @override
  void onClose() {
    cameraController.dispose();
    super.onClose();
  }
}
