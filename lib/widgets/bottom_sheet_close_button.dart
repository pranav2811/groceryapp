import 'package:flutter/material.dart';
import 'package:groceryapp/common/constants/colors.dart';

class BottomSheetCloseButton extends StatelessWidget {
  const BottomSheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
      },
      shape: const CircleBorder(),
      color: darkBlack,
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(
          Icons.close,
          color: white,
          size: 28,
        ),
      ),
    );
  }
}
