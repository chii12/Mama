import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tixywttvqntmgkuvpazl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRpeHl3dHR2cW50bWdrdXZwYXpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE2NzM0NzAsImV4cCI6MjA1NzI0OTQ3MH0.RRpWMI9szvKBxQ14XexJf3SK3VrmDcO2eu-S52sVzW0',
  );
  runApp(MamEaseApp());
}


class MamEaseApp extends StatelessWidget {
  const MamEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}