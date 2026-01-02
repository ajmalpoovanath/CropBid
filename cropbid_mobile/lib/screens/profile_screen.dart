import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final result = await ApiService.getProfile(widget.userId);
    if (mounted) {
      setState(() {
        _profileData = result['success'] ? result['data'] : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profileData == null
              ? const Center(child: Text("Could not load profile"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 1. Profile Picture
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileData!['profile_picture'] != null
                            ? NetworkImage(_profileData!['profile_picture'])
                            : null,
                        child: _profileData!['profile_picture'] == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(height: 20),

                      // 2. Info Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.person, color: Colors.teal),
                                title: const Text("Name"),
                                subtitle: Text(_profileData!['full_name'] ?? _profileData!['company_name'] ?? "N/A"),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.phone, color: Colors.teal),
                                title: const Text("Phone"),
                                subtitle: Text(_profileData!['phone'] ?? "N/A"),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.location_on, color: Colors.teal),
                                title: const Text("Address"),
                                subtitle: Text(_profileData!['address'] ?? "N/A"),
                              ),
                              const Divider(),
                              ListTile(
                                leading: const Icon(Icons.badge, color: Colors.teal),
                                title: const Text("Role"),
                                subtitle: Text(_profileData!['role'] ?? "N/A"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}