import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<User?> currentUser = Rx<User?>(null);
  RxMap<String, dynamic> userData = RxMap<String, dynamic>();

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (currentUser.value != null) {
      try {
        print("Fetching user data for UID: ${currentUser.value!.uid}");
        DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection('users')
            .doc(currentUser.value!.uid)
            .get();

        if (snapshot.exists) {
          userData.value =
              snapshot.data() ?? {}; // Fetch data if document exists
          print("Fetched user data: ${userData.value}");
        } else {
          print("User document does not exist in Firestore.");
        }
      } catch (e) {
        print("Error fetching user data: $e"); // Debug error
      }
    } else {
      print("No current user found.");
    }
  }

  void logout() async {
    await _auth.signOut();
    Get.offNamed('/login');
  }
}
