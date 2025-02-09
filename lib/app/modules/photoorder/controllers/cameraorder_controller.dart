import 'package:get/get.dart';
import 'package:camera/camera.dart';

class CameraViewController extends GetxController {
  late CameraController cameraController;
  List<CameraDescription> cameras = [];
  var isCameraInitialized = false.obs;
  var capturedImagePath = ''.obs; // Holds the path of the captured image

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

  @override
  void onClose() {
    cameraController.dispose();
    super.onClose();
  }
}
