import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:grocerygo/Screens/login_page.dart';
import 'package:grocerygo/main.dart';
import 'package:grocerygo/config/theme/my_theme.dart';
import 'package:grocerygo/app/routes/app_pages.dart';
import 'package:grocerygo/app/data/local/my_shared_pref.dart';
import 'package:grocerygo/config/translations/localization_service.dart';

void main() {
  setUpAll(() async {
    // Initialize Firebase before running the tests
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await MySharedPref.init();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the app with ScreenUtilInit and GetMaterialApp structure
    await tester.pumpWidget(
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
            theme: MyTheme.getThemeData(isLight: true), // Set default theme
            home:
                const LoginScreen(), // You can replace with any widget for testing
            getPages: AppPages.routes,
            locale: Locale('en'), // Set default locale for tests
            translations: LocalizationService.getInstance(),
          );
        },
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
