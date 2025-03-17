import 'package:flutter/material.dart';

class DoctorScreen extends StatelessWidget {
  const DoctorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Doctor Advice"), backgroundColor: Colors.pinkAccent),
      body: Center(child: Text("Doctor betlogs Here")),
    );
  }
}
