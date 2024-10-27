import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../components/no_data.dart';
import '../controllers/category_controller.dart';

class CategoryView extends GetView<CategoryController> {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Category', style: context.theme.textTheme.bodyMedium),
        centerTitle: true,
      ),
      body: const NoData(text: 'This is Category Screen'),
    );
  }
}
