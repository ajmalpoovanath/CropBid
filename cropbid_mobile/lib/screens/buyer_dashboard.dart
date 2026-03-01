import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'crop_detail_screen.dart';
import 'profile_screen.dart';
import 'inbox_screen.dart';
import 'orders_screen.dart';

class BuyerDashboard extends StatefulWidget {
  final int userId;

  const BuyerDashboard({super.key, required this.userId});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;
  List<dynamic> _crops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    final crops = await ApiService.getAllCrops();
    if (mounted) {
      setState(() {
        _crops = crops;
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "${ApiService.baseUrl.replaceAll('/api', '')}$path";
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.paddyGreen))
          : RefreshIndicator(
              onRefresh: _fetchCrops,
              color: AppTheme.paddyGreen,
              child: _crops.isEmpty 
                ? const Center(child: Text("No crops available in the market.", style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _crops.length,
                    itemBuilder: (context, index) {
                      final crop = _crops[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        color: AppTheme.surfaceMoss, // Using theme card color
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          // 🚀 FIX: Reliable navigation to Detail Screen
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CropDetailScreen(
                                  crop: crop, 
                                  userId: widget.userId
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                                child: Container(
                                  height: 180,
                                  width: double.infinity,
                                  color: AppTheme.backgroundForest,
                                  child: crop['image'] != null
                                      ? Image.network(
                                          _getImageUrl(crop['image']), 
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50, color: Colors.white12),
                                        )
                                      : const Icon(Icons.agriculture, size: 50, color: AppTheme.paddyGreen),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            crop['name'] ?? "Unknown Crop", 
                                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                                          ),
                                        ),
                                        Text(
                                          "₹${crop['base_price']}", 
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.paddyGreen)
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Quantity: ${crop['quantity']} kg", 
                                      style: const TextStyle(color: Colors.white70)
                                    ),
                                    const Divider(height: 24, color: Colors.white10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on, size: 16, color: AppTheme.clayRed),
                                            const SizedBox(width: 4),
                                            const Text("Kerala, India", style: TextStyle(color: AppTheme.clayRed, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        const Row(
                                          children: [
                                            Text("View Details", style: TextStyle(color: AppTheme.paddyGreen, fontWeight: FontWeight.bold)),
                                            Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.paddyGreen),
                                          ],
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
                    },
                  ),
            ),
      InboxScreen(userId: widget.userId),
      OrdersScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Marketplace", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surfaceMoss,
        indicatorColor: AppTheme.paddyGreen.withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70), 
            selectedIcon: Icon(Icons.home, color: Colors.white), 
            label: 'Home'
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white70), 
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.white), 
            label: 'Chats'
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined, color: Colors.white70), 
            selectedIcon: Icon(Icons.shopping_bag, color: Colors.white), 
            label: 'Orders'
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white70), 
            selectedIcon: Icon(Icons.person, color: Colors.white), 
            label: 'Profile'
          ),
        ],
      ),
    );
  }
}