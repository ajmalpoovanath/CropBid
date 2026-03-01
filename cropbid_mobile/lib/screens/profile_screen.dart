import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isDarkMode = true; // For the theme toggle visual

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ApiService.getProfile(widget.userId);
      if (mounted) {
        setState(() {
          // 🛡️ FIX: If response is successful, use data. If not, _userData stays null.
          if (response['success']) {
            _userData = response['data'];
          }
          _isLoading = false; // 👈 FIX: Always stop loading to break the loop
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "${ApiService.baseUrl.replaceAll('/api', '')}$path";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.paddyGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. Identity Card
                  Card(
                    color: AppTheme.surfaceMoss,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.paddyGreen.withOpacity(0.1),
                            backgroundImage: _userData?['profile_picture'] != null
                                ? NetworkImage(_getImageUrl(_userData!['profile_picture']))
                                : null,
                            child: _userData?['profile_picture'] == null
                                ? const Icon(Icons.person, size: 50, color: AppTheme.paddyGreen)
                                : null,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userData?['full_name'] ?? "Setup Your Name",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            _userData?['email'] ?? "No email provided",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.paddyGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userData?['role']?.toString().toUpperCase() ?? "USER",
                              style: const TextStyle(color: AppTheme.paddyGreen, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // 2. Action Menu (Point 7)
                  _buildProfileItem(
                    icon: Icons.location_on_outlined,
                    title: "My Address",
                    subtitle: _userData?['address'] ?? "No address added yet",
                    onTap: () => _showEditDialog("Update Address", "address"),
                  ),
                  _buildProfileItem(
                    icon: Icons.phone_outlined,
                    title: "Phone Number",
                    subtitle: _userData?['phone'] ?? "No phone added yet",
                    onTap: () => _showEditDialog("Update Phone", "phone"),
                  ),
                  _buildProfileItem(
                    icon: Icons.shield_outlined,
                    title: "Security Settings",
                    subtitle: "Change Password",
                    onTap: () => _showEditDialog("Change Password", "password"),
                  ),
                  
                  // 3. Appearance Settings (Point 7 & 8)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: AppTheme.surfaceMoss,
                    child: SwitchListTile(
                      activeColor: AppTheme.paddyGreen,
                      title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      subtitle: const Text("Keep the forest theme", style: TextStyle(color: Colors.white70)),
                      secondary: const Icon(Icons.dark_mode_outlined, color: AppTheme.paddyGreen),
                      value: _isDarkMode,
                      onChanged: (val) {
                        setState(() => _isDarkMode = val);
                      },
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. Logout Section (Point 3)
                  TextButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, color: AppTheme.clayRed),
                    label: const Text(
                      "Logout Account",
                      style: TextStyle(color: AppTheme.clayRed, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 100), 
                ],
              ),
            ),
    );
  }

  // Generic Edit Dialog for Demo purposes
  void _showEditDialog(String title, String field) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceMoss,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), 
            style: ElevatedButton.styleFrom(minimumSize: const Size(80, 40)),
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.surfaceMoss,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.paddyGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }
}