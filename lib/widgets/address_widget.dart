import 'package:flutter/material.dart';
import 'package:groceryapp/widgets/address_form_field_widget.dart';

class AddressWidget extends StatelessWidget {
  final TextEditingController flatHouseFloorBuildingController;
  final TextEditingController areaSectorLocalityController;
  final TextEditingController nearbyLandmarkController;

  const AddressWidget({
    super.key,
    required this.flatHouseFloorBuildingController,
    required this.areaSectorLocalityController,
    required this.nearbyLandmarkController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: AddressFormFieldWidget(
            controller: flatHouseFloorBuildingController,
            hint: "Flat / House no / Floor / Building *",
          ),
        ),
        AddressFormFieldWidget(
          controller: areaSectorLocalityController,
          hint: "Area / Sector / Locality *",
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: AddressFormFieldWidget(
            controller: nearbyLandmarkController,
            hint: "Nearby landmark (optional)",
          ),
        ),
      ],
    );
  }
}
