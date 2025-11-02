import 'package:get/get.dart';
import 'package:groceryapp/app/modules/orders/bindings/orders_binding.dart';
import 'package:groceryapp/app/modules/orders/views/user_order_view.dart';
import 'package:groceryapp/app/modules/photoorder/views/cameraorder_view.dart';

import '../modules/base/bindings/base_binding.dart';
import '../modules/base/views/base_view.dart';
import '../modules/calendar/bindings/calendar_binding.dart';
import '../modules/calendar/views/calendar_view.dart';
import '../modules/cart/bindings/cart_binding.dart';
import '../modules/cart/views/cart_view.dart';
import '../modules/category/bindings/category_binding.dart';
import '../modules/category/views/category_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/photoorder/bindings/cameraorder_binding.dart';
import '../modules/product_details/bindings/product_details_binding.dart';
import '../modules/product_details/views/product_details_view.dart';
import '../modules/products/bindings/products_binding.dart';
import '../modules/products/views/products_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';
import '../modules/welcome/bindings/welcome_binding.dart';
import '../modules/welcome/views/welcome_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  // ignore: constant_identifier_names
  static const INITIAL = Routes.splash;

  static final routes = [
    GetPage(
      name: _Paths.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.welcome,
      page: () => const WelcomeView(),
      binding: WelcomeBinding(),
    ),
    GetPage(
      name: '/user-orders',
      page: () => const UserOrdersView(),
      binding: UserOrdersBinding(),
    ),
    GetPage(
      name: _Paths.base,
      page: () => const BaseView(),
      binding: BaseBinding(),
    ),
    GetPage(
      name: _Paths.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.cart,
      page: () => const CartView(),
      binding: CartBinding(),
    ),
    GetPage(
      name: _Paths.productDetails,
      page: () => const ProductDetailsView(),
      binding: ProductDetailsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: _Paths.category,
      page: () => const CategoryView(),
      binding: CategoryBinding(),
    ),
    GetPage(
      name: _Paths.calendar,
      page: () => const CalendarView(),
      binding: CalendarBinding(),
    ),
    GetPage(
      name: _Paths.profile,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.products,
      page: () => const ProductsView(),
      binding: ProductsBinding(),
    ),
    GetPage(
      name: _Paths.camera,
      page: () => const CameraView(),
      binding: CameraBinding(),
    ),
  ];
}
