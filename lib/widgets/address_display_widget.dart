import 'package:flutter/material.dart';

class AddressDisplayWidget extends StatelessWidget {
  final Map<String, dynamic> addressData;

  const AddressDisplayWidget({Key? key, required this.addressData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address:',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 5),
          Text(
            '${addressData['flatHouseFloorBuilding'] ?? 'N/A'}, ${addressData['areaSectorLocality'] ?? 'N/A'}',
            style: textTheme.bodyLarge?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 5),
          Text(
            'Landmark: ${addressData['nearbyLandmark'] ?? 'N/A'}',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Text(
            'Contact: ${addressData['phone'] ?? 'N/A'}',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
