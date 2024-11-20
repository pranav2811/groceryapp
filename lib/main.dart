import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:grocerygo/Screens/admin_home_screen.dart';
import 'app/data/local/my_shared_pref.dart';
import 'app/routes/app_pages.dart';
import 'config/theme/my_theme.dart';
import 'config/translations/localization_service.dart';
import 'package:grocerygo/Screens/login_page.dart'; // Assuming this is your login page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseAppCheck.instance.activate();

  await MySharedPref.init();

  User? currentUser = FirebaseAuth.instance.currentUser;

  runApp(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      rebuildFactor: (old, data) => true,
      builder: (context, widget) {
        return GetMaterialApp(
          title: "Grocery App",
          useInheritedMediaQuery: true,
          debugShowCheckedModeBanner: false,
          theme: MyTheme.getThemeData(isLight: MySharedPref.getThemeIsLight()),
          home: currentUser != null
              ? RoleBasedRedirector(user: currentUser)
              : const LoginScreen(),
          getPages: AppPages.routes,
          locale: MySharedPref.getCurrentLocal(),
          translations:
              LocalizationService.getInstance(), // Set up localization
        );
      },
    ),
  );
}

class RoleBasedRedirector extends StatelessWidget {
  final User user;

  const RoleBasedRedirector({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error fetching user data.')),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        if (userData['role'] == 'admin') {
          return const AdminHomeScreen();
        } else {
          Future.delayed(Duration.zero, () {
            Get.offAllNamed(Routes.base);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}
