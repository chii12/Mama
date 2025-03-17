import 'package:flutter/material.dart';

class TipDetailsScreen extends StatelessWidget {
  const TipDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tip of the Day"),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  "assets/images/tips.png",
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Baby's Development Updates",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.pink),
              ),
              const SizedBox(height: 10),

              // Tip Content
              const Text(
                "Your baby is growing every day! Ensure a healthy pregnancy by maintaining a balanced diet, staying active, and having regular check-ups with your doctor.",
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Additional Tip
              const Text(
                "Tip: Try to incorporate folic acid, calcium, and iron into your daily meals for better baby development!",
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
