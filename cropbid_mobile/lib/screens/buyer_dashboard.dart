import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; 
import 'chat_screen.dart'; 
import 'inbox_screen.dart'; 
import 'orders_screen.dart';
import 'crop_detail_screen.dart'; 
import 'package:url_launcher/url_launcher.dart';

class BuyerDashboard extends StatefulWidget {
  final int? userId; 

  const BuyerDashboard({super.key, this.userId});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;
  List<dynamic> _marketCrops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketplace();
  }

  Future<void> _loadMarketplace() async {
    final crops = await ApiService.getAllCrops();
    if (mounted) {
      setState(() {
        _marketCrops = crops;
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  // 🖼️ Helper to get the correct Image URL dynamically
  String _getImageUrl(String? path) {
    if (path == null) return "";
    if (path.startsWith('http')) return path;
    // Removes '/api' from the baseUrl to get the root server address
    return "${ApiService.baseUrl.replaceAll('/api', '')}$path";
  }

  Future<void> _openMap(double lat, double lng) async {
    final Uri appleMapsUrl = Uri.parse('maps://?q=$lat,$lng');
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      if (await canLaunchUrl(appleMapsUrl)) {
        await launchUrl(appleMapsUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _marketCrops.isEmpty
              ? const Center(child: Text("No crops available right now."))
              : RefreshIndicator(
                  onRefresh: _loadMarketplace,
                  child: ListView.builder(
                    itemCount: _marketCrops.length,
                    itemBuilder: (context, index) {
                      final crop = _marketCrops[index];
                      final double? lat = crop['farmer_lat'] != null ? double.tryParse(crop['farmer_lat'].toString()) : null;
                      final double? lng = crop['farmer_lng'] != null ? double.tryParse(crop['farmer_lng'].toString()) : null;

                      return GestureDetector(
                        onTap: () {
                          if (widget.userId == null) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CropDetailScreen(
                                crop: crop,
                                userId: widget.userId!,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: crop['image'] != null
                                      ? Image.network(
                                          _getImageUrl(crop['image']),
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50),
                                        )
                                      : const Icon(Icons.agriculture, size: 50, color: Colors.grey),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          crop['name'],
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          "₹${crop['base_price']}", // 💰 Removed /kg
                                          style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "Quantity: ${crop['quantity']} kg",
                                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      crop['description'] ?? "No description...",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const Divider(height: 25),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (lat != null && lng != null)
                                          TextButton.icon(
                                            onPressed: () => _openMap(lat, lng),
                                            icon: const Icon(Icons.location_on, size: 16),
                                            label: const Text("See Location"),
                                          ),
                                        const Text("View Details ➡️", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      
      widget.userId != null ? InboxScreen(userId: widget.userId!) : const Center(child: Text("Error")),
      widget.userId != null ? OrdersScreen(userId: widget.userId!) : const Center(child: Text("Error")),
      widget.userId != null ? ProfileScreen(userId: widget.userId!) : const Center(child: Text("Error")),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Crop Marketplace"),
              centerTitle: true,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                ),
              ],
            )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), activeIcon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}