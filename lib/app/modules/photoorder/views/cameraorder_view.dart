import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cameraorder_controller.dart';

class CameraView extends GetView<CameraViewController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        centerTitle: true,
      ),
      body: Obx(() {
        // 1) Loading while camera initializes
        if (!controller.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2) If a photo was captured, show preview + actions
        if (controller.capturedImagePath.value.isNotEmpty) {
          return Stack(
            children: [
              // Photo preview (fills entire screen)
              Positioned.fill(
                child: Image.file(
                  File(controller.capturedImagePath.value),
                  fit: BoxFit.cover,
                ),
              ),

              // Place Order button (bottom center)
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: ElevatedButton(
                  onPressed: () async {
                    // Calls controller logic that:
                    // - confirms
                    // - opens address bottom sheet
                    // - uploads file to Storage
                    // - writes Firestore order
                    await controller.placeOrder(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Recapture (bottom-right FAB)
              Positioned(
                right: 20,
                bottom: 90,
                child: FloatingActionButton(
                  heroTag: 'recapture_fab',
                  onPressed: () {
                    controller.capturedImagePath.value = ''; // reset preview
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.refresh, color: Colors.blue),
                ),
              ),
            ],
          );
        }

        // 3) Default: show live camera preview with Capture button
        return Stack(
          children: [
            Positioned.fill(child: CameraPreview(controller.cameraController)),

            // Capture Image button (bottom center)
            Positioned(
              left: 20,
              right: 20,
              bottom: 35,
              child: ElevatedButton(
                onPressed: () async {
                  final image = await controller.cameraController.takePicture();
                  controller.capturedImagePath.value = image.path;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Capture Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
