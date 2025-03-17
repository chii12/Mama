import 'package:flutter/material.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late Animation<Offset> _cloudAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for floating clouds
    _cloudController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _cloudAnimation = Tween<Offset>(
      begin: Offset(0, 0),
      end: Offset(0, 0.03),
    ).animate(CurvedAnimation(
      parent: _cloudController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _cloudController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: Stack(
        children: [
          // Floating clouds
          Positioned(
            top: 50,
            left: 30,
            child: SlideTransition(
              position: _cloudAnimation,
              child: Image.asset("assets/images/cloud1.png", width: 100),
            ),
          ),
          Positioned(
            top: 100,
            right: 30,
            child: SlideTransition(
              position: _cloudAnimation,
              child: Image.asset("assets/images/cloud2.png", width: 120),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/images/startmain_logo.png", width: 200),
                SizedBox(height: 20),
                Text(
                  "Mom Ease",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    "Get Started!",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}