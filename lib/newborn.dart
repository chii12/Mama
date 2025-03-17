import 'package:flutter/material.dart';

class NewbornScreen extends StatelessWidget {
  const NewbornScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Newborn Care"), backgroundColor: Colors.pinkAccent),
      body: Center(child: Text("Newborn Care Tips Here")),
    );
  }
}
