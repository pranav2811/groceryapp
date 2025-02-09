import 'package:get/get.dart';
import '../controllers/cameraorder_controller.dart';

class CameraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CameraViewController>(
      () => CameraViewController(),
    );
  }
}
