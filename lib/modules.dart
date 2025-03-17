import 'package:flutter/material.dart';

class PregnancyModulesScreen extends StatelessWidget {
  const PregnancyModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pregnancy Modules"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: const Center(
        child: Text("Pregnancy Modules Content Here"),
      ),
    );
  }
}
