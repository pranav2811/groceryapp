import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grocerygo/common/constants/colors.dart';
import 'package:grocerygo/common/enums/order_for.dart';
import 'package:grocerygo/widgets/address_type_widget.dart';
import 'package:grocerygo/widgets/address_widget.dart';
import 'package:grocerygo/widgets/bottom_sheet_close_button.dart';
import 'package:grocerygo/widgets/custom_button.dart';
import 'package:grocerygo/widgets/name_and_phone_number_widget.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:grocerygo/widgets/address_display_widget.dart';

class AddAddressBottomSheet extends StatefulWidget {
  final String userId; // User ID to query the address collection

  const AddAddressBottomSheet({Key? key, required this.userId})
      : super(key: key);

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

        // Populate address and personal details if available
        if (data['address'] != null) {
          setState(() {
            existingAddress = data['address'];
            hasAddress = true;
          });
        }
        if (data['name'] != null) {
          nameController.text = data['name']; // Populate name from Firestore
        }
        if (data['phone'] != null) {
          phoneController.text = data['phone']; // Populate phone from Firestore
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> saveAddress() async {
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      Map<String, dynamic> newAddress = {
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address saved successfully!')),
      );

      Navigator.pop(context, newAddress);

      // Show payment options after address is saved
      showPaymentOptions(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save address: $e')),
      );
    }
  }

  void showPaymentOptions(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select Payment Option",
                style: textTheme?.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.money),
                title: const Text("Cash on Delivery"),
                onTap: () async {
                  try {
                    // Update Firestore with the payment status
                    await FirebaseFirestore.instance.collection('orders').add({
                      'userId': userId,
                      'paymentStatus': 'Cash on Delivery',
                      'timestamp': FieldValue.serverTimestamp(),
                      // Add other order details here as needed
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Cash on Delivery selected. Order placed successfully.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to place order: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code),
                title: const Text("UPI"),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('UPI selected')),
                  );
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
              color: white,
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
              Navigator.pop(context);
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
                    const Icon(
                      Icons.home,
                      color: Colors.black,
                      size: 28,
                    ),
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
          const Divider(height: 1, color: grey),
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
        const Divider(height: 1, color: grey),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14).copyWith(top: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Who are you ordering for?",
                style: textTheme?.labelSmall?.copyWith(
                  color: grey.withOpacity(0.7),
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
                    color: grey.withOpacity(0.7),
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
