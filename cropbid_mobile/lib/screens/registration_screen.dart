import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  String _selectedRole = 'BUYER'; // Default role
  bool _isLoading = false;

  void _register() async {
    setState(() => _isLoading = true);
    final response = await ApiService.register(
      _userController.text, 
      _passController.text, 
      _emailController.text, 
      _selectedRole
    );
    setState(() => _isLoading = false);

    if (response['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account Created! Please Login 🌿"), backgroundColor: AppTheme.primaryGreen)
      );
      Navigator.pop(context); // Go back to Login
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Failed: ${response['message']}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Join the Community", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)
            ),
            const SizedBox(height: 8),
            const Text("Create an account to start trading fresh produce", style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 40),

            // User Input
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                hintText: "Username",
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 20),

            // Email Input
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: "Email Address",
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 20),

            // Password Input
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Password",
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primaryGreen),
              ),
            ),
            
            const SizedBox(height: 30),

            // Role Selection Section
            const Text("I am a:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
            const SizedBox(height: 12),
            Row(
              children: [
                _roleChip("BUYER", Icons.shopping_basket_outlined),
                const SizedBox(width: 15),
                _roleChip("FARMER", Icons.agriculture_outlined),
              ],
            ),

            const SizedBox(height: 40),

            // Submit Button
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : ElevatedButton(
                    onPressed: _register,
                    child: const Text("CREATE ACCOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String role, IconData icon) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey[300]!),
            boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(
                role, 
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey, 
                  fontWeight: FontWeight.bold,
                  fontSize: 12
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}