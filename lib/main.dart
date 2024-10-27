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
  // Wait for bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseAppCheck.instance.activate();

  // Initialize shared preferences
  await MySharedPref.init();

  // Check if user is logged in
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
          theme: MyTheme.getThemeData(
              isLight: MySharedPref
                  .getThemeIsLight()), // Use theme from shared preferences
          home: currentUser != null
              ? RoleBasedRedirector(
                  user: currentUser) // Custom logic for role-based redirection
              : const LoginScreen(), // Otherwise, load the login screen directly
          getPages: AppPages.routes, // Define the app pages for GetX navigation
          locale: MySharedPref
              .getCurrentLocal(), // Set locale based on shared preferences
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
    // Firestore query to check user role
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
                child:
                    CircularProgressIndicator()), // Show loading while fetching user role
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
          // If user data doesn't exist in Firestore, log them out and show login screen
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;

        // Redirect based on user role
        if (userData['role'] == 'admin') {
          // If user is admin, redirect to Admin Home Screen
          return const AdminHomeScreen();
        } else {
          // If user is customer, redirect to the base page (GetX route)
          Future.delayed(Duration.zero, () {
            Get.offAllNamed(Routes.base); // Replace with your base route
          });
          return const Scaffold(
            body: Center(
                child: CircularProgressIndicator()), // Loading while navigating
          );
        }
      },
    );
  }
}
