import 'package:flutter/material.dart';
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
              // 1. Logo
              const Icon(
                Icons.agriculture,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              
              const Text(
                'CropBid Login',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28, 
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 40),

              // 2. Username Input
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Password Input
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

              // 4. LOGIN BUTTON
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

                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  // Call API
                  final result = await ApiService.login(username, password);

                  // Hide loading
                  if (context.mounted) Navigator.pop(context);

                  if (result['success']) {
                    // --- SUCCESS LOGIC STARTS HERE ---
                    final data = result['data'];
                    final role = data['role']; 
                    
                    // Get the flag from backend (default to false if missing)
                    final bool isProfileComplete = data['is_profile_complete'] ?? false; 

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Login Successful! 🎉")),
                      );

                      // OPTION A: Profile is Empty -> Go to Completion Screen
                      if (isProfileComplete == false) {
                        print("Profile Incomplete. Redirecting...");
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompleteProfileScreen(
                              userId: data['id'],
                              role: role,
                            ),
                          ),
                        );
                      } 
                      // OPTION B: Profile is Done -> Go to Dashboard
                      else {
                        print("Profile Complete. Going to Dashboard...");
                        
                        if (role == 'FARMER') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              // 🛠️ CHANGED: Removed 'const' and passed userId
                              builder: (context) => FarmerDashboard(userId: data['id']),
                            ),
                          );
                        } else if (role == 'BUYER') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const BuyerDashboard()),
                          );
                        }
                      }
                    }
                    // --- SUCCESS LOGIC ENDS HERE ---
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result['message']),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              
              // 5. Register Link
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
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