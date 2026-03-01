import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart'; // 🌿 Added your theme
import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class CompleteProfileScreen extends StatefulWidget {
  final int userId;
  final String role; 

  const CompleteProfileScreen({
    super.key, 
    required this.userId, 
    required this.role
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _fullNameController = TextEditingController(); 
  final _companyController = TextEditingController();  
  final _licenseController = TextEditingController();  

  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _getLocation() async {
    var status = await Permission.location.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission is required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _submitProfile() async {
    if (_phoneController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await ApiService.updateProfile(
      userId: widget.userId,
      role: widget.role,
      phone: _phoneController.text,
      address: _addressController.text,
      lat: _latitude ?? 0.0,
      lng: _longitude ?? 0.0,
      fullName: widget.role == 'FARMER' ? _fullNameController.text : null,
      companyName: widget.role == 'BUYER' ? _companyController.text : null,
      licenseNumber: widget.role == 'BUYER' ? _licenseController.text : null,
      imagePath: _imageFile?.path,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.role == 'FARMER' 
                ? FarmerDashboard(userId: widget.userId) // 👈 FIX: Passing userId
                : BuyerDashboard(userId: widget.userId), // 👈 FIX: Passing userId
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: AppBar(
        title: const Text("Complete Your Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 📸 Profile Picture Picker
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.surfaceMoss,
                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null 
                        ? const Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.paddyGreen) 
                        : null,
                  ),
                  Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 18, backgroundColor: AppTheme.paddyGreen, child: const Icon(Icons.edit, size: 18, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text("Upload Professional Photo", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),

            // 📝 Role Specific Fields
            if (widget.role == 'FARMER') _buildForestField(_fullNameController, "Full Name", Icons.person_outline),
            if (widget.role == 'BUYER') ...[
              _buildForestField(_companyController, "Company Name", Icons.business_outlined),
              const SizedBox(height: 20),
              _buildForestField(_licenseController, "License Number", Icons.badge_outlined),
            ],
            const SizedBox(height: 20),

            // 📞 Common Fields
            _buildForestField(_phoneController, "Phone Number", Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),

            // 📍 Location Field
            Row(
              children: [
                Expanded(child: _buildForestField(_addressController, "Location", Icons.location_on_outlined)),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.my_location, color: AppTheme.paddyGreen),
                  style: IconButton.styleFrom(backgroundColor: AppTheme.surfaceMoss),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // 🔘 Submit Button
            _isLoading 
              ? const CircularProgressIndicator(color: AppTheme.paddyGreen)
              : ElevatedButton(
                  onPressed: _submitProfile,
                  child: const Text("SAVE & CONTINUE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildForestField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.paddyGreen),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: AppTheme.surfaceMoss,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}