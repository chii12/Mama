import 'package:flutter/material.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nutrition Guide"), backgroundColor: Colors.pinkAccent),
      body: Center(child: Text("Nutrition Advice Here")),
    );
  }
}
