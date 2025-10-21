// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../utils/constants.dart';
import '../../../components/category_item.dart';
import '../../../components/custom_form_field.dart';
import '../../../components/custom_icon_button.dart';
import '../../../components/dark_transition.dart';
import '../../../components/product_item.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  String getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12 && hour > 5) {
      return 'Good Morning';
    } else if (hour < 17 && hour > 12) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<String?> fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          return data['name']?.toString();
        }
      }
    } catch (e) {
      debugPrint('Error fetching user name: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return DarkTransition(
      offset: Offset(context.width, -1),
      isDark: !controller.isLightTheme,
      builder: (context, _) => Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: -100.h,
              child: SvgPicture.asset(
                Constants.container,
                fit: BoxFit.fill,
                color: theme.canvasColor,
              ),
            ),
            ListView(
              children: [
                Column(
                  children: [
                    // Greeting + avatar + theme toggle
                    FutureBuilder<String?>(
                      future: fetchUserName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Padding(
                            padding: EdgeInsets.only(top: 24.h),
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (snapshot.hasData && snapshot.data != null) {
                          return ListTile(
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 24.w),
                            title: Text(
                              '${getGreetingMessage()},',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12.sp),
                            ),
                            subtitle: Text(
                              snapshot.data!,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            leading: CircleAvatar(
                              radius: 22.r,
                              backgroundColor: theme.primaryColorDark,
                              child: ClipOval(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Image.asset(Constants.avatar),
                                ),
                              ),
                            ),
                            trailing: CustomIconButton(
                              onPressed: () =>
                                  controller.onChangeThemePressed(),
                              backgroundColor: theme.primaryColorDark,
                              icon: GetBuilder<HomeController>(
                                id: 'Theme',
                                builder: (_) => Icon(
                                  controller.isLightTheme
                                      ? Icons.dark_mode_outlined
                                      : Icons.light_mode_outlined,
                                  color: theme.appBarTheme.iconTheme?.color,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return Padding(
                            padding: EdgeInsets.only(
                                left: 24.w, right: 24.w, top: 16.h),
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Welcome',
                                    style: theme.textTheme.titleSmall)),
                          );
                        }
                      },
                    ),

                    10.verticalSpace,

                    // Search
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: CustomFormField(
                        backgroundColor: theme.primaryColorDark,
                        textSize: 14.sp,
                        hint: 'Search Product',
                        hintFontSize: 14.sp,
                        hintColor: theme.hintColor,
                        maxLines: 1,
                        borderRound: 60.r,
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.h, horizontal: 10.w),
                        focusedBorderColor: Colors.transparent,
                        isSearchField: true,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        prefixIcon: SvgPicture.asset(
                          Constants.searchIcon,
                          fit: BoxFit.none,
                        ),
                      ),
                    ),

                    20.verticalSpace,

                    // Carousel
                    SizedBox(
                      width: double.infinity,
                      height: 158.h,
                      child: CarouselSlider.builder(
                        options: CarouselOptions(
                          initialPage: 1,
                          viewportFraction: 0.9,
                          enableInfiniteScroll: true,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 3),
                        ),
                        itemCount: controller.cards.length,
                        itemBuilder: (context, itemIndex, pageViewIndex) {
                          return Image.asset(controller.cards[itemIndex]);
                        },
                      ),
                    ),
                  ],
                ),

                // Body content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      20.verticalSpace,

                      // Categories header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Categories', style: theme.textTheme.titleSmall),
                          GestureDetector(
                            onTap: () => Get.toNamed('/category'),
                            child: Text(
                              'See all',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),

                      16.verticalSpace,

                      // Categories row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: controller.categories
                            .map((c) => CategoryItem(category: c))
                            .toList(),
                      ),

                      20.verticalSpace,

                      // Best selling header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Best selling', style: theme.textTheme.titleSmall),
                          GestureDetector(
                            onTap: () => controller.fetchBestSelling(),
                            child: Text(
                              'Shuffle',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),

                      16.verticalSpace,

                      // Best selling grid from Firestore (randomized)
                      GetBuilder<HomeController>(
                        id: 'BestSelling',
                        builder: (_) {
                          if (controller.isLoadingBestSelling) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (controller.bestSelling.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.h),
                              child: Text('No items found',
                                  style: theme.textTheme.bodyMedium),
                            );
                          }
                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16.w,
                              mainAxisSpacing: 16.h,
                              mainAxisExtent: 214.h,
                            ),
                            shrinkWrap: true,
                            primary: false,
                            itemCount: controller.bestSelling.length,
                            itemBuilder: (context, index) {
                              return ProductItem(
                                product: controller.bestSelling[index],
                              );
                            },
                          );
                        },
                      ),

                      20.verticalSpace,
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
