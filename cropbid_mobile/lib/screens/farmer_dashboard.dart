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
  // 0 = Home, 1 = Chats, 2 = Orders, 3 = Profile
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      // TAB 0: THE CROP LIST (Home)
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
                      // Safety check for nulls
                      final bool isSold = crop['is_sold'] ?? false;
                      final double highestBid = double.tryParse(crop['highest_bid'].toString()) ?? 0.0;
                      
                      // 👇 GET ORDER STATUS FROM BACKEND
                      final String? orderStatus = crop['order_status']; 

                      // 👇 DETERMINE BADGE & STATUS TEXT LOGIC
                      String badgeText = "";
                      Color badgeColor = Colors.grey;
                      String statusMessage = "";
                      Color statusColor = Colors.orange;

                      if (isSold) {
                        if (orderStatus == 'CONFIRMED') {
                           // Buyer has Paid
                           badgeText = "PAID ✅";
                           badgeColor = Colors.green;
                           statusMessage = "📦 Ready to Ship (Check Orders Tab)";
                           statusColor = Colors.green;
                        } else if (orderStatus == 'DELIVERED') {
                           // Order Complete
                           badgeText = "SOLD";
                           badgeColor = Colors.blueGrey;
                           statusMessage = "✅ Order Completed";
                           statusColor = Colors.blueGrey;
                        } else {
                           // Waiting for Payment
                           badgeText = "RESERVED";
                           badgeColor = Colors.grey;
                           statusMessage = "⏳ Waiting for Payment";
                           statusColor = Colors.orange;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 3,
                        // 🎨 Visual Trick: Grey out card if Sold
                        color: isSold ? Colors.grey[50] : Colors.white,
                        child: Column(
                          children: [
                            ListTile(
                              leading: crop['image'] != null 
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        "http://127.0.0.1:8000${crop['image']}", 
                                        width: 50, 
                                        height: 50, 
                                        fit: BoxFit.cover,
                                        errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported),
                                      ),
                                    )
                                  : const Icon(Icons.agriculture, size: 40, color: Colors.green),
                              
                              // 👇 1. TITLE ROW WITH DYNAMIC BADGE
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      crop['name'], 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: isSold ? TextDecoration.lineThrough : null,
                                        color: isSold ? Colors.grey : Colors.black
                                      )
                                    )
                                  ),
                                  
                                  // 🏷️ STATUS BADGE
                                  if (isSold)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(4)),
                                      child: Text(badgeText, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  // 🟠 OFFERS BADGE
                                  else if (highestBid > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                                      child: const Text("OFFERS!", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              
                              subtitle: Text("Qty: ${crop['quantity']} kg\nHighest Bid: ₹$highestBid"),
                              trailing: Text("₹${crop['base_price']}", style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                            ),

                            // 👇 2. CONDITIONAL BUTTON / STATUS MESSAGE
                            if (!isSold)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                                    label: const Text("VIEW BIDS", style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                              )
                            else 
                              // Show the specific status message calculated above
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(statusMessage, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
      
      // TAB 1: INBOX SCREEN
      widget.userId != null 
          ? InboxScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),

      // TAB 2: ORDERS SCREEN
      widget.userId != null 
          ? OrdersScreen(userId: widget.userId!, isFarmer: true) 
          : const Center(child: Text("Error: No User ID")),

      // TAB 3: PROFILE SCREEN
      widget.userId != null 
          ? ProfileScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0 
          ? AppBar(
              title: const Text("My Farm 🚜"),
              backgroundColor: Colors.green,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                ),
              ],
            )
          : null, 

      body: _pages[_selectedIndex],

      // FAB only on Home Tab
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
                  if (result == true) {
                    _loadCrops(); 
                  }
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'My Farm',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message), 
            label: 'Chats',
          ),
          BottomNavigationBarItem( 
            icon: Icon(Icons.shopping_bag), 
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}