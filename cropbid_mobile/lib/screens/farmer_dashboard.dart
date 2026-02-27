import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
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

  // 🖼️ Helper to get the correct Image URL dynamically
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "${ApiService.baseUrl.replaceAll('/api', '')}$path";
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      _isLoadingCrops 
          ? const Center(child: CircularProgressIndicator()) 
          : RefreshIndicator(
              onRefresh: _loadCrops,
              child: _crops.isEmpty 
                ? const Center(child: Text("No crops listed yet. Click + to add.")) 
                : ListView.builder(
                    itemCount: _crops.length,
                    itemBuilder: (context, index) {
                      final crop = _crops[index];
                      final bool isSold = crop['is_sold'] ?? false;
                      final double highestBid = double.tryParse(crop['highest_bid'].toString()) ?? 0.0;
                      final String? orderStatus = crop['order_status']; 

                      String badgeText = "";
                      Color badgeColor = Colors.grey;
                      String statusMessage = "";
                      Color statusColor = Colors.orange;

                      if (isSold) {
                        if (orderStatus == 'CONFIRMED') {
                           badgeText = "PAID ✅";
                           badgeColor = Colors.green;
                           statusMessage = "📦 Ready to Ship (Check Orders Tab)";
                           statusColor = Colors.green;
                        } else if (orderStatus == 'DELIVERED') {
                           badgeText = "SOLD";
                           badgeColor = Colors.blueGrey;
                           statusMessage = "✅ Order Completed";
                           statusColor = Colors.blueGrey;
                        } else {
                           badgeText = "RESERVED";
                           badgeColor = Colors.grey;
                           statusMessage = "⏳ Waiting for Payment";
                           statusColor = Colors.orange;
                        }
                      }

                      // 🚜 REMOVED: InkWell/GestureDetector wrapper to disable clicking
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 4,
                        clipBehavior: Clip.antiAlias,
                        color: isSold ? Colors.grey[50] : Colors.white,
                        child: Column(
                          children: [
                            ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200],
                                  child: crop['image'] != null 
                                      ? Image.network(
                                          _getImageUrl(crop['image']), 
                                          fit: BoxFit.cover,
                                          errorBuilder: (c,e,s) => const Icon(Icons.broken_image),
                                        )
                                      : const Icon(Icons.agriculture, color: Colors.green),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      crop['name'], 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        decoration: isSold ? TextDecoration.lineThrough : null,
                                      )
                                    )
                                  ),
                                  if (isSold)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                                      child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  else if (highestBid > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("OFFERS!", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text("Total Qty: ${crop['quantity']} kg\nHighest Bid: ₹$highestBid"),
                              ),
                              trailing: Text("₹${crop['base_price']}", style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),

                            if (!isSold)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                                        label: const Text("VIEW BIDS", style: TextStyle(color: Colors.white)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0),
                                        onPressed: () {
                                          Navigator.push(
                                            context, 
                                            MaterialPageRoute(builder: (context) => ViewBidsScreen(
                                              cropId: crop['id'], 
                                              cropName: crop['name']
                                            ))
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else 
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(statusMessage, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
      
      widget.userId != null ? InboxScreen(userId: widget.userId!) : const Center(child: Text("Error")),
      widget.userId != null ? OrdersScreen(userId: widget.userId!, isFarmer: true) : const Center(child: Text("Error")),
      widget.userId != null ? ProfileScreen(userId: widget.userId!) : const Center(child: Text("Error")),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0 
          ? AppBar(
              title: const Text("My Farm 🚜"),
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

      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () async {
                  if (widget.userId == null) return;
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => AddCropScreen(userId: widget.userId!))
                  );
                  if (result == true) _loadCrops(); 
              },
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.agriculture), label: 'My Farm'),
          BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}