import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import '../services/api_service.dart';
import 'register_screen.dart';
import 'complete_profile_screen.dart';
import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 🛠️ Updated Helper function to handle the FCM Token handshake without crashing
  Future<void> _handleFcmToken(int userId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 👇 Bypasses the 'apns-token-not-set' error common on simulators
      String? token = await messaging.getToken().catchError((err) {
        print("Token fetch skipped (expected on simulator): $err");
        return null; // Return null so the app continues
      });

      if (token != null) {
        print("FCM Token: $token");
        // Send the token to Django to associate it with this user
        await ApiService.saveDeviceToken(userId, token);
      } else {
        print("No FCM token generated (Simulator mode active).");
      }
    } catch (e) {
      print("Handled FCM error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.agriculture, size: 80, color: Colors.green),
              const SizedBox(height: 20),
              const Text(
                'CropBid Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 40),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true, 
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final username = _usernameController.text;
                  final password = _passwordController.text;

                  if (username.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill in all fields")),
                    );
                    return;
                  }

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  final result = await ApiService.login(username, password);

                  if (context.mounted) Navigator.pop(context);

                  if (result['success']) {
                    final data = result['data'];
                    final role = data['role']; 
                    final int userId = data['id'];
                    final bool isProfileComplete = data['is_profile_complete'] ?? false; 

                    // 👇 This now has the bypass for simulator errors
                    await _handleFcmToken(userId);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Login Successful! 🎉")),
                      );

                      if (isProfileComplete == false) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompleteProfileScreen(userId: userId, role: role),
                          ),
                        );
                      } else {
                        if (role == 'FARMER') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => FarmerDashboard(userId: userId)),
                          );
                        } else if (role == 'BUYER') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => BuyerDashboard(userId: userId)),
                          );
                        }
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('LOGIN', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                },
                child: const Text('New here? Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}