import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_crop_screen.dart';
import 'profile_screen.dart';
import 'inbox_screen.dart';
import 'view_bids_screen.dart';
import 'orders_screen.dart';

class FarmerDashboard extends StatefulWidget {
  final int? userId;

  const FarmerDashboard({super.key, this.userId});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;
  List<dynamic> _crops = [];
  bool _isLoadingCrops = true;

  @override
  void initState() {
    super.initState();
    debugPrint("DASHBOARD DEBUG: Farmer Login ID is ${widget.userId}");
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    if (widget.userId == null) return;
    final crops = await ApiService.getMyCrops(widget.userId!);
    if (mounted) {
      setState(() {
        _crops = crops;
        _isLoadingCrops = false;
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
      _isLoadingCrops
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.paddyGreen),
            )
          : RefreshIndicator(
              color: AppTheme.paddyGreen,
              onRefresh: _loadCrops,
              child: _crops.isEmpty
                  ? const Center(
                      child: Text(
                        "No crops listed yet. Click + to add.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 10, bottom: 100),
                      itemCount: _crops.length,
                      itemBuilder: (context, index) {
                        final crop = _crops[index];
                        final bool isSold = crop['is_sold'] ?? false;
                        final double highestBid =
                            double.tryParse(crop['highest_bid'].toString()) ??
                            0.0;
                        final String? orderStatus = crop['order_status'];

                        String badgeText = "";
                        Color badgeColor = Colors.grey;
                        String statusMessage = "";
                        Color statusColor = AppTheme.paddyGreen;

                        if (isSold) {
                          if (orderStatus == 'CONFIRMED') {
                            badgeText = "PAID ✅";
                            badgeColor = AppTheme.paddyGreen;
                            statusMessage = "📦 Ready to Ship";
                          } else if (orderStatus == 'DELIVERED') {
                            badgeText = "SOLD";
                            badgeColor = Colors.blueGrey;
                            statusMessage = "✅ Order Completed";
                            statusColor = Colors.blueGrey;
                          } else {
                            badgeText = "RESERVED";
                            badgeColor = Colors.orange;
                            statusMessage = "⏳ Waiting for Payment";
                            statusColor = Colors.orange;
                          }
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    color: AppTheme
                                        .backgroundForest, // Match theme
                                    child: crop['image'] != null
                                        ? Image.network(
                                            _getImageUrl(crop['image']),
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.white24,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.agriculture,
                                            color: AppTheme.paddyGreen,
                                            size: 30,
                                          ),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        crop['name'],
                                        style: TextStyle(
                                          color: Colors.white, // 👈 Force White
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          decoration: isSold
                                              ? TextDecoration.lineThrough
                                              : null,
                                          decorationColor: Colors.white54,
                                        ),
                                      ),
                                    ),
                                    if (isSold)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else if (highestBid > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.clayRed,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          "NEW BID!",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Lot: ${crop['quantity']} kg",
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ), // 👈 Fixed contrast
                                      const SizedBox(height: 4),
                                      Text(
                                        "Top Bid: ₹$highestBid",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ), // 👈 Fixed contrast
                                    ],
                                  ),
                                ),
                                trailing: Text(
                                  "₹${crop['base_price']}",
                                  style: const TextStyle(
                                    color: AppTheme.paddyGreen,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              if (!isSold)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    16,
                                  ),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.gavel_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "MANAGE BIDS",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ViewBidsScreen(
                                            cropId: crop['id'],
                                            cropName: crop['name'],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    statusMessage,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

      widget.userId != null
          ? InboxScreen(userId: widget.userId!)
          : const Center(child: Text("Error")),
      widget.userId != null
          ? OrdersScreen(userId: widget.userId!, isFarmer: true)
          : const Center(child: Text("Error")),
      widget.userId != null
          ? ProfileScreen(userId: widget.userId!)
          : const Center(child: Text("Error")),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.backgroundForest, // Force background
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text(
                "CropBid",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,

      body: _pages[_selectedIndex],

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppTheme.paddyGreen,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: Colors.white,
              ),
              onPressed: () async {
                if (widget.userId == null) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddCropScreen(userId: widget.userId!),
                  ),
                );
                if (result == true) _loadCrops();
              },
            )
          : null,

      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.surfaceMoss,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.home, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.chat_bubble, color: Colors.white),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.shopping_bag, color: Colors.white),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
