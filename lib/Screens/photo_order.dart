import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final backCamera = _cameras?.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    if (backCamera != null) {
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
      );

      await _cameraController?.initialize();
      setState(() {}); // Update the UI after initialization
    }
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final XFile photo = await _cameraController!.takePicture();
      File? croppedFile = await _cropImage(File(photo.path));
      if (croppedFile != null) {
        setState(() {
          _imageFile = croppedFile;
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    final XFile? galleryPhoto = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (galleryPhoto != null) {
      File? croppedFile = await _cropImage(File(galleryPhoto.path));
      if (croppedFile != null) {
        setState(() {
          _imageFile = croppedFile;
        });
      }
    }
  }

  Future<File?> _cropImage(File imageFile) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Document',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Document',
        ),
      ],
    );
    if (croppedFile != null) {
      return File(croppedFile.path);
    } else {
      return null;
    }
  }

  void _placeOrder() {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture or select a photo.')),
      );
      return;
    }

    // Implement your order placement logic here

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed'),
        content: const Text('Your order has been placed successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _imageFile = null; // Reset image after order placement
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Widget _buildCameraOverlay() {
    return Stack(
      children: [
        if (_cameraController != null && _cameraController!.value.isInitialized)
          CameraPreview(_cameraController!)
        else
          const Center(child: CircularProgressIndicator()),
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            onPressed: _selectFromGallery,
            backgroundColor: Colors.white.withOpacity(0.8),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order by Photo'),
        backgroundColor: Colors.deepOrange,
      ),
      body: _imageFile == null
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
                    onPressed: _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Place Order'),
                  ),
                ),
              ],
            ),
    );
  }
}
