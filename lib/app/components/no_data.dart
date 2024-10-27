import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../utils/constants.dart';

class NoData extends StatelessWidget {
  final String? text;
  const NoData({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          80.verticalSpace,
          Image.asset(
            Constants.logo,
            width: 313.w,
            height: 260.h,
          ),
          20.verticalSpace,
          Text(
            text ?? 'No Data',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}