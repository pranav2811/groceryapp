import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'dart:io'; // Needed to display the captured image

import '../controllers/cameraorder_controller.dart'; // Import the correct controller

class CameraView extends GetView<CameraViewController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Camera"),
      ),
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        } else if (controller.capturedImagePath.value.isNotEmpty) {
          // Display the captured image and the "Place Order" button
          return Stack(
            children: [
              // Display the captured image
              Positioned.fill(
                child: Image.file(
                  File(controller.capturedImagePath.value),
                  fit: BoxFit.cover, // Make the image cover the entire screen
                ),
              ),
              // Place "Place Order" button at the bottom
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic for placing the order
                      Get.snackbar('Order', 'Your order has been placed!');
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20), // Reduce corner radius
                      ),
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0, // Reduce vertical padding
                        horizontal:
                            40.0, // Reduce horizontal padding to make it smaller
                      ), // Background color of the button
                      minimumSize: const Size(
                          150, 40), // Set a minimum size for the button
                    ),
                    child: const Text(
                      'Place Order',
                      style: TextStyle(
                        fontSize: 16, // Slightly smaller font size
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // Ensure text is white
                      ),
                    ),
                  ),
                ),
              ),
              // Add the circular "Recapture" button at the bottom right
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    // Allow the user to retake the picture
                    controller.capturedImagePath.value =
                        ''; // Reset the image path
                  },
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.blue, // Blue text for the refresh icon
                  ),
                ),
              ),
            ],
          );
        } else {
          // Display the camera preview if no image is captured yet
          return Stack(
            children: [
              CameraPreview(controller.cameraController),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ElevatedButton(
                  onPressed: () async {
                    // Capture the image when the button is pressed
                    final image =
                        await controller.cameraController.takePicture();
                    controller.capturedImagePath.value =
                        image.path; // Store the image path
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 32.0,
                    ), // Background color of the capture button
                  ),
                  child: const Text(
                    'Capture Image',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
