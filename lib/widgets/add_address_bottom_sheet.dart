import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:groceryapp/common/enums/order_for.dart';
import 'package:groceryapp/widgets/address_type_widget.dart';
import 'package:groceryapp/widgets/address_widget.dart';
import 'package:groceryapp/widgets/bottom_sheet_close_button.dart';
import 'package:groceryapp/widgets/custom_button.dart';
import 'package:groceryapp/widgets/name_and_phone_number_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:groceryapp/common/constants/colors.dart';
import 'package:get/get.dart';

class AddAddressBottomSheet extends StatefulWidget {
  final String userId; // User ID to query the address collection

  const AddAddressBottomSheet({super.key, required this.userId});

  @override
  State<AddAddressBottomSheet> createState() => _AddAddressBottomSheetState();
}

class _AddAddressBottomSheetState extends State<AddAddressBottomSheet> {
  TextTheme? textTheme;
  var orderFor = OrderFor.myself;
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final flatHouseFloorBuildingController = TextEditingController();
  final areaSectorLocalityController = TextEditingController();
  final nearbyLandmarkController = TextEditingController();
  bool hasAddress = false;
  Map<String, dynamic>? existingAddress;

  @override
  void initState() {
    super.initState();
    fetchUserAddress();
  }

  Future<void> fetchUserAddress() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userSnapshot.exists && userSnapshot.data() != null) {
        var data = userSnapshot.data() as Map<String, dynamic>;

        if (data['address'] != null) {
          setState(() {
            existingAddress = data['address'];
            hasAddress = true;
          });
        }
        if (data['name'] != null) {
          nameController.text = data['name'];
        }
        if (data['phone'] != null) {
          phoneController.text = data['phone'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      _showError('Failed to load saved address');
    }
  }

  Future<void> saveAddress() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        _showError('User not logged in.');
        return;
      }

      final newAddress = {
        'flatHouseFloorBuilding': flatHouseFloorBuildingController.text,
        'areaSectorLocality': areaSectorLocalityController.text,
        'nearbyLandmark': nearbyLandmarkController.text,
        'phone': phoneController.text,
        'name': nameController.text,
      };

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'address': newAddress,
        'name': nameController.text,
        'phone': phoneController.text,
      });

      _showSuccess('Address saved successfully!');
      // Close this sheet, returning the address upward (if caller needs it)
      Navigator.pop(context, newAddress);
      // Immediately show payment options
      showPaymentOptions(context);
    } catch (e) {
      _showError('Failed to save address: $e');
    }
  }

  void showPaymentOptions(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showError('User not logged in.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final localTextTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Payment Option",
                style: localTextTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text("Cash on Delivery"),
                onTap: () async {
                  try {
                    await FirebaseFirestore.instance
                        .collection('photo_orders')
                        .add({
                      'userId': userId,
                      'paymentStatus': 'Cash on Delivery',
                      'timestamp': FieldValue.serverTimestamp(),
                      // TODO: include more fields if needed (address snapshot, totals, imageUrl, etc.)
                    });

                    Navigator.pop(context); // close payment sheet
                    Get.offAllNamed('/home'); // go to Home
                    _showSuccess('Order placed successfully (COD).');
                  } catch (e) {
                    _showError('Failed to place order: $e');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text("UPI"),
                onTap: () {
                  Navigator.pop(context); // close payment sheet
                  Get.offAllNamed('/home'); // go to Home
                  _showSuccess('UPI selected.');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetCloseButton(),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              color: Colors.white,
            ),
            child:
                hasAddress ? displayExistingAddress() : displayAddAddressForm(),
          ),
        ],
      ),
    );
  }

  Widget displayExistingAddress() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Saved Address",
            style: textTheme?.labelLarge?.copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // close address sheet
              showPaymentOptions(context);
            },
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.home, color: Colors.black, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${existingAddress?['flatHouseFloorBuilding'] ?? ''}, ${existingAddress?['areaSectorLocality'] ?? ''}',
                            style: textTheme?.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (existingAddress?['nearbyLandmark'] != null)
                            Text(
                              'Landmark: ${existingAddress?['nearbyLandmark']}',
                              style: textTheme?.bodyMedium?.copyWith(
                                color: Colors.black,
                              ),
                            ),
                          const SizedBox(height: 5),
                          Text(
                            'Name: ${existingAddress?['name'] ?? ''}',
                            style: textTheme?.bodyMedium?.copyWith(
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Phone: ${existingAddress?['phone'] ?? ''}',
                            style: textTheme?.bodyMedium?.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.only(top: 20.0, bottom: 15),
            child: CustomButton(
              text: "Add New Address",
              borderRadius: 10,
              onPressed: () {
                setState(() {
                  hasAddress = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget displayAddAddressForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            "Enter complete address",
            style: textTheme?.labelLarge?.copyWith(fontSize: 20),
          ),
        ),
        const Divider(height: 1, color: Colors.grey),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14).copyWith(top: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Who are you ordering for?",
                style: textTheme?.labelSmall?.copyWith(
                  color: Colors.grey.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  orderForButtonWidget(
                    label: "Myself",
                    isSelected: orderFor == OrderFor.myself,
                    onClick: () {
                      if (orderFor != OrderFor.myself) {
                        setState(() {
                          orderFor = OrderFor.myself;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 25),
                  orderForButtonWidget(
                    label: "Someone else",
                    isSelected: orderFor == OrderFor.someoneElse,
                    onClick: () {
                      if (orderFor != OrderFor.someoneElse) {
                        setState(() {
                          orderFor = OrderFor.someoneElse;
                        });
                      }
                    },
                  ),
                ],
              ),
              if (orderFor == OrderFor.someoneElse)
                NameAndPhoneNumberWidget(
                  nameController: nameController,
                  phoneController: phoneController,
                ),
              Padding(
                padding: const EdgeInsets.only(top: 30, bottom: 10),
                child: Text(
                  "Save address as *",
                  style: textTheme?.labelSmall?.copyWith(
                    color: Colors.grey.withOpacity(0.7),
                  ),
                ),
              ),
              const AddressTypeWidget(),
              AddressWidget(
                flatHouseFloorBuildingController:
                    flatHouseFloorBuildingController,
                areaSectorLocalityController: areaSectorLocalityController,
                nearbyLandmarkController: nearbyLandmarkController,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 15),
                child: CustomButton(
                  text: "Save Address",
                  borderRadius: 10,
                  onPressed: saveAddress,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Styled GetX snackbars
  void _showSuccess(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 3),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red.shade700,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(12),
      borderRadius: 10,
      duration: const Duration(seconds: 4),
    );
    // Also log to console for debugging
    debugPrint('Error: $message');
  }

  Widget orderForButtonWidget({
    required String label,
    required bool isSelected,
    required VoidCallback onClick,
  }) =>
      GestureDetector(
        onTap: onClick,
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: primaryColorVariant,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                label,
                style: textTheme?.labelMedium?.copyWith(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
}
