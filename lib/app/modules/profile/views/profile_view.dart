import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.bodyMedium),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.currentUser.value == null ||
            controller.userData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User info card
              SizedBox(
                width: double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30.r,
                          backgroundColor: theme.primaryColorDark,
                          child: Text(
                            controller.userData['name'] != null
                                ? controller.userData['name'][0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 24.sp,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          controller.userData['name'] ?? 'User',
                          style: theme.textTheme.headlineMedium,
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          controller.userData['email'] ?? 'No email found',
                          style: theme.textTheme.bodySmall,
                        ),
                        SizedBox(height: 10.h),
                        TextButton(
                          onPressed: () {
                            // TODO: activity screen
                          },
                          child: Text(
                            'View activity',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // Profile / mode
              _buildSwitchTile('Your profile', '100% completed'),
              _buildSwitchTile('Veg Mode', '', isSwitch: true),
              _buildSwitchTile('Appearance', 'Light'),

              SizedBox(height: 20.h),

              // Orders
              Text(
                'Food Orders',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildListTile(
                'Your orders',
                Icons.shopping_bag,
                onTap: () {
                  // Use route if you registered it
                  Get.toNamed('/user-orders');
                  // or:
                  // Get.to(() => const UserOrdersView());
                },
              ),
              _buildListTile(
                'Favorite orders (Coming Soon)',
                Icons.favorite,
                onTap: () {
                  // TODO: favorite orders screen
                },
              ),

              SizedBox(height: 40.h),

              // Logout
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showLogoutConfirmationDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ---------------- helpers ----------------

  Widget _buildSwitchTile(String title, String value, {bool isSwitch = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: isSwitch
          ? Switch(
              value: false,
              onChanged: (val) {},
            )
          : Text(
              value,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  // list tile with onTap
  Widget _buildListTile(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.logout(context);
              Get.back();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
