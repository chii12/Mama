import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String code; // Ensure this is defined

  const ResetPasswordScreen({Key? key, required this.code}) : super(key: key); // Fix constructor

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      print("Error: No active session found.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Session expired. Request a new reset link."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      userEmail = user.email;
    });
    print("User Email: $userEmail"); // Debugging
  }

  Future<void> resetPassword() async {
    if (userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: No user session. Try again."), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a new password"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Password reset successful!"), backgroundColor: Colors.green),
      );

      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Enter New Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      prefixIcon: Icon(Icons.lock, color: Colors.pink),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text("Reset Password", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
