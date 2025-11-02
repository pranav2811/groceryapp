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
  final isCameraInitialized = false.obs;

  /// Local path of the last captured image (used by placeOrder)
  final capturedImagePath = ''.obs;

  /// Spinner while placing order
  final isPlacingOrder = false.obs;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void onInit() async {
    super.onInit();
    await initCamera();
  }

  // ========== Camera ==========
  Future<void> initCamera() async {
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await cameraController.initialize();
      isCameraInitialized.value = true;
    }
  }

  Future<void> capturePhoto() async {
    if (!isCameraInitialized.value) {
      Get.snackbar('Camera', 'Camera is not ready yet.');
      return;
    }
    try {
      if (!cameraController.value.isInitialized ||
          cameraController.value.isTakingPicture) {
        return;
      }
      final XFile xfile = await cameraController.takePicture();
      capturedImagePath.value = xfile.path;
      Get.snackbar('Captured', 'Photo captured successfully.');
    } catch (e) {
      Get.snackbar('Capture failed', e.toString());
    }
  }

  // ========== Order flow ==========
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Place this order with the selected photo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    final address = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAddressBottomSheet(userId: user.uid),
    );
    if (address == null) return;

    try {
      isPlacingOrder.value = true;

      // resolve name
      String userName = user.displayName ?? '';
      if (userName.isEmpty) {
        final snap = await _firestore.collection('users').doc(user.uid).get();
        final d = snap.data() ?? {};
        userName = (d['name'] ?? d['displayName'] ?? user.email ?? user.uid)
            .toString();
      }

      final file = File(capturedImagePath.value);
      if (!await file.exists()) {
        Get.snackbar('File missing', 'Captured image file not found on disk.');
        return;
      }
      final ext = p.extension(file.path).toLowerCase();
      final contentType = ext == '.png'
          ? 'image/png'
          : (ext == '.webp' ? 'image/webp' : 'image/jpeg');

      final objectName =
          'photo_order_${user.uid}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final ref = _storage.ref().child('photo_orders/$objectName');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final snap = await ref.putFile(file, metadata);
      await snap.ref.getMetadata(); // verify
      final imageUrl = await ref.getDownloadURL();

      // WRITE in the format apps expects
      await _firestore.collection('photo_orders').add({
        'userId': user.uid, // <- REQUIRED
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(), // <- use createdAt
        'address': address,
        'imageUrl': imageUrl,
        'paymentMethod': 'cod',
        'status': 'pending',
        'type': 'photo_order',
      });

      capturedImagePath.value = '';
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order Placed'),
          content: const Text('Your photo order has been placed successfully!'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
    } finally {
      isPlacingOrder.value = false;
    }
  }

  @override
  void onClose() {
    if (isCameraInitialized.value) {
      cameraController.dispose();
    }
    super.onClose();
  }
}
