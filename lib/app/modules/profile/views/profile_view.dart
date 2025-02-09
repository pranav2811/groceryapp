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
      body: Obx(
        () {
          if (controller.currentUser.value == null ||
              controller.userData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card stretched across the screen
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
                          // Circle with Initial Letter
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
                          // Display the email fetched from Firestore
                          Text(
                            controller.userData['email'] ?? 'No email found',
                            style: theme.textTheme.bodySmall,
                          ),
                          SizedBox(height: 10.h),
                          TextButton(
                            onPressed: () {
                              // Navigate to user's activity screen
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

                // Collections and Money Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoCard('Collections', Icons.bookmark),
                    _buildInfoCard('Money', Icons.account_balance_wallet,
                        value: '₹0'),
                  ],
                ),
                SizedBox(height: 20.h),

                // Profile and Mode Switches
                _buildSwitchTile('Your profile', '100% completed'),
                _buildSwitchTile('Veg Mode', '', isSwitch: true),
                _buildSwitchTile('Appearance', 'Light'),
                SizedBox(height: 20.h),

                // Your rating
                _buildInfoTile('Your rating', '4.71', icon: Icons.star),
                SizedBox(height: 20.h),

                // Orders Section
                Text(
                  'Food Orders',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildListTile('Your orders', Icons.shopping_bag),
                _buildListTile('Favorite orders', Icons.favorite),

                // Add some space before the logout button
                SizedBox(height: 40.h),

                // Logout Button
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
        },
      ),
    );
  }

  // Helper widget for switch tiles
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

  // Helper widget for information cards
  Widget _buildInfoCard(String title, IconData icon, {String value = ''}) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 10),
              Text(title),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for list tiles
  Widget _buildListTile(String title, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
    );
  }

  // Helper widget for displaying info tiles
  Widget _buildInfoTile(String title, String value, {IconData? icon}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: icon != null ? Icon(icon) : null,
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Method to show logout confirmation dialog
  void _showLogoutConfirmationDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // Close the dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.logout(context); // Call logout method in controller
              Get.back(); // Close the dialog
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
