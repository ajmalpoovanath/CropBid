import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import 'farmer_dashboard.dart';
import 'buyer_dashboard.dart';

class CompleteProfileScreen extends StatefulWidget {
  final int userId;
  final String role; // 'FARMER' or 'BUYER'

  const CompleteProfileScreen({
    super.key, 
    required this.userId, 
    required this.role
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  // Text Controllers
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Specific Fields
  final _fullNameController = TextEditingController(); // For Farmer
  final _companyController = TextEditingController();  // For Buyer
  final _licenseController = TextEditingController();  // For Buyer

  // Data Holders
  File? _imageFile;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  // 📸 Function to Pick Image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 📍 Function to Get Location
  Future<void> _getLocation() async {
    // Check permissions
    var status = await Permission.location.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission is required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = "Lat: ${position.latitude}, Lng: ${position.longitude}"; // Auto-fill for now
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 💾 Submit Form
  void _submitProfile() async {
    if (_phoneController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill common fields")));
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

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        // Navigate to the correct Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => widget.role == 'FARMER' 
                ? const FarmerDashboard() 
                : const BuyerDashboard(),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'])));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 1. Profile Picture Picker
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                child: _imageFile == null 
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey) 
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Tap to upload photo"),
            const SizedBox(height: 30),

            // 2. Role Specific Fields
            if (widget.role == 'FARMER') ...[
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
            ],

            if (widget.role == 'BUYER') ...[
              TextField(
                controller: _companyController,
                decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _licenseController,
                decoration: const InputDecoration(labelText: "License Number", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
            ],

            // 3. Common Fields
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),

            // 4. Location Picker
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: "Address / Location", border: OutlineInputBorder()),
                  ),
                ),
                IconButton(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 5. Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitProfile,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("SAVE & CONTINUE", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}