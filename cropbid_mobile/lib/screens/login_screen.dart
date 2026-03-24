import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'buyer_dashboard.dart';
import 'farmer_dashboard.dart';
import 'registration_screen.dart';
import 'complete_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        _userController.text,
        _passController.text,
      );
      if (mounted) setState(() => _isLoading = false);

      if (response['success'] && mounted) {
        // 🔑 THE FIX: Extract the primary LOGIN ID (User Table ID)
        final userData = response['data']['data'] ?? response['data'];

        // 🛡️ Robust Extraction for the Login ID (e.g., 11 or 12)
        final dynamic rawId = userData['id'] ?? userData['user_id'];
        final int? userId = int.tryParse(rawId?.toString() ?? "");
        final String role = (userData['role'] ?? 'BUYER')
            .toString()
            .toUpperCase();
        final bool isProfileComplete = userData['is_profile_complete'] ?? false;

        // 🕵️ DEBUG: Jerry Jo MUST be ID 12. Tom MUST be ID 11.
        debugPrint(
          "LOGIN SUCCESS: Role=$role, LoginID=$userId, ProfileComplete=$isProfileComplete",
        );

        if (userId != null) {
          if (!isProfileComplete) {
            // 🚀 NEW USER: Redirect to profile setup
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CompleteProfileScreen(userId: userId, role: role),
              ),
            );
          } else {
            // ✅ EXISTING USER: Send to correct dashboard using the LOGIN ID
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => role == 'FARMER'
                    ? FarmerDashboard(userId: userId)
                    : BuyerDashboard(userId: userId),
              ),
            );
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Invalid Login ❌"),
            backgroundColor: AppTheme.clayRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("LOGIN ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Connection Error. Check Server.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🌿 Professional Header with Deep Forest Gradient
            Container(
              height: 320,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.paddyGreen, AppTheme.backgroundForest],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(100),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.eco_rounded, size: 90, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "CropBid",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    "Kerala's Trusted Agri-Market",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign in to your account",
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 40),

                  // 👤 Username Field
                  TextField(
                    controller: _userController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Username",
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: AppTheme.paddyGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔒 Password Field
                  TextField(
                    controller: _passController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Password",
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: AppTheme.paddyGreen,
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Password reset link sent to email!"),
                          ),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: AppTheme.clayRed),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.paddyGreen,
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _login,
                            child: const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "New here?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationScreen(),
                          ),
                        ),
                        child: const Text(
                          "Create Account",
                          style: TextStyle(
                            color: AppTheme.paddyGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
