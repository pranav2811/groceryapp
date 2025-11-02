// photo_order_page.dart  (your Stateful one)
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:groceryapp/widgets/add_address_bottom_sheet.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class PhotoOrderPage extends StatefulWidget {
  const PhotoOrderPage({super.key});

  @override
  _PhotoOrderPageState createState() => _PhotoOrderPageState();
}

class _PhotoOrderPageState extends State<PhotoOrderPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _placing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      final backCamera = _cameras?.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (backCamera != null) {
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController?.initialize();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      if (_cameraController!.value.isTakingPicture) return;
      final XFile x = await _cameraController!.takePicture();
      final File? cropped = await _cropImage(File(x.path));
      if (cropped != null) setState(() => _imageFile = cropped);
    } catch (e) {
      debugPrint('Take photo error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to take photo: $e')),
        );
      }
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final XFile? x = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (x != null) {
        final File? cropped = await _cropImage(File(x.path));
        if (cropped != null) setState(() => _imageFile = cropped);
      }
    } catch (e) {
      debugPrint('Gallery pick error: $e');
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Document'),
      ],
    );
    return cropped != null ? File(cropped.path) : null;
  }

  Future<void> _placeOrder() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or select a photo.')),
      );
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text(
            'Do you want to place this order with the selected photo?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (proceed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAddressBottomSheet(userId: user.uid),
    );
    if (result == null) return;

    // bottom sheet returns whole object, store directly
    final address = Map<String, dynamic>.from(result['address'] as Map);
    final paymentMethod = (result['paymentMethod'] as String?) ?? 'cod';

    setState(() => _placing = true);

    try {
      // denormalize user name
      String userName = user.displayName ?? '';
      if (userName.isEmpty) {
        try {
          final u = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          final d = u.data() ?? {};
          userName = (d['name'] ?? d['displayName'] ?? user.email ?? user.uid)
              .toString();
        } catch (_) {
          userName = user.email ?? user.uid;
        }
      }

      final file = _imageFile!;
      if (!await file.exists()) {
        throw 'Captured image file not found.';
      }

      final ext = p.extension(file.path).toLowerCase();
      final contentType = ext == '.png'
          ? 'image/png'
          : (ext == '.webp' ? 'image/webp' : 'image/jpeg');

      final objectName =
          'photo_order_${user.uid}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final ref =
          FirebaseStorage.instance.ref().child('photo_orders/$objectName');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'userId': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final snap = await ref.putFile(file, metadata);
      await snap.ref.getMetadata();
      final imageUrl = await ref.getDownloadURL();

      // write in unified shape
      await FirebaseFirestore.instance.collection('photo_orders').add({
        'userId': user.uid, // <- REQUIRED
        'userName': userName,
        'createdAt': FieldValue.serverTimestamp(), // <- use createdAt
        'address': {
          'address': address,
        },
        'imageUrl': imageUrl,
        'paymentMethod': paymentMethod,
        'status': 'pending',
        'type': 'photo_order',
      });

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Order Placed'),
          content: const Text('Your photo order has been placed successfully!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      setState(() => _imageFile = null);
    } catch (e) {
      debugPrint('Place order error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _buildCameraOverlay() {
    final ready =
        _cameraController != null && _cameraController!.value.isInitialized;
    return Stack(
      children: [
        if (ready)
          CameraPreview(_cameraController!)
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            onPressed: _selectFromGallery,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: const Icon(Icons.photo_library, color: Colors.black),
          ),
        ),
        Positioned(
          bottom: 20,
          right: MediaQuery.of(context).size.width / 2 - 40,
          child: FloatingActionButton(
            onPressed: _takePhoto,
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = _imageFile == null
        ? _buildCameraOverlay()
        : Column(
            children: [
              Expanded(
                child: Image.file(
                  _imageFile!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _placing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: _placing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Place Order'),
                ),
              ),
            ],
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order by Photo'),
        backgroundColor: Colors.deepOrange,
      ),
      body: child,
    );
  }
}
