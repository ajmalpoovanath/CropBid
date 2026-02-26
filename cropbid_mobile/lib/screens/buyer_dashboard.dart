import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; 
import 'chat_screen.dart'; 
import 'inbox_screen.dart'; 
import 'orders_screen.dart';
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
    setState(() {
      _selectedIndex = index;
    });
  }

  // 📍 NEW: Professional Maps Launcher Logic
  Future<void> _openMap(double lat, double lng) async {
  // Apple Maps URL scheme (Best for iOS Simulator/iPhone)
  final Uri appleMapsUrl = Uri.parse('maps://?q=$lat,$lng');
  
  // Google Maps URL scheme (Fallback)
  final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

  try {
    if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch maps';
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

  String _calculateTimeLeft(String? endTime) {
    if (endTime == null) return "Auction Not Started";
    final end = DateTime.parse(endTime);
    final now = DateTime.now().toUtc();
    final diff = end.difference(now); 
    
    if (diff.isNegative) return "Auction Expired";
    return "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
  }

  void _showBidDialog(BuildContext context, int cropId, String cropName, String basePriceString) {
    final TextEditingController _amountController = TextEditingController();
    final double basePrice = double.tryParse(basePriceString) ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Bid for $cropName"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Minimum Bid: ₹$basePriceString", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Your Offer (₹)",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                final amountText = _amountController.text;
                if (amountText.isEmpty) return;
                final double offer = double.tryParse(amountText) ?? 0.0;

                if (offer < basePrice) {
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Offer too low! Minimum is ₹$basePrice"), backgroundColor: Colors.red),
                  );
                  return;
                }

                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Placing Bid...")));
                final success = await ApiService.placeBid(widget.userId!, cropId, amountText);

                if (mounted) {
                   if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bid Placed! Timer Started ⏱️")));
                      _loadMarketplace();
                   } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to place bid.")));
                   }
                }
              },
              child: const Text("Submit Bid", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      // TAB 0: MARKETPLACE (Integrated with Maps)
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
                      
                      // Pull location from updated serializer
                      final double? lat = crop['farmer_lat'] != null ? double.tryParse(crop['farmer_lat'].toString()) : null;
                      final double? lng = crop['farmer_lng'] != null ? double.tryParse(crop['farmer_lng'].toString()) : null;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🖼️ Image Section
                            Container(
                              height: 150,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: crop['image'] != null
                                  ? Image.network(
                                      "http://127.0.0.1:8000${crop['image']}",
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50),
                                    )
                                  : const Icon(Icons.agriculture, size: 50, color: Colors.grey),
                            ),

                            // 📝 Details Section
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            crop['name'],
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          // 📍 NEW: Location Icon Button
                                          if (lat != null && lng != null)
                                            IconButton(
                                              icon: const Icon(Icons.location_on, color: Colors.blue, size: 20),
                                              tooltip: "Navigate to Farm",
                                              onPressed: () => _openMap(lat, lng),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        "₹${crop['base_price']}/kg",
                                        style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Bid Info Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Highest: ₹${crop['highest_bid'] ?? crop['base_price']}", 
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                                      ),
                                      Text(
                                        crop['auction_end_time'] != null ? "Active ⏱️" : "No Bids", 
                                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                  if (crop['auction_end_time'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        _calculateTimeLeft(crop['auction_end_time']),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ),

                                  const SizedBox(height: 15),
                                  
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                          onPressed: () {
                                            if (widget.userId == null) return;
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ChatScreen(
                                                  myId: widget.userId!,
                                                  otherId: crop['farmer_user_id'] ?? crop['farmer'], 
                                                  otherName: crop['farmer_name'] ?? "Farmer", 
                                                ),
                                              ),
                                            );
                                          },
                                          label: const Text("CHAT"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.gavel, size: 18, color: Colors.white),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                          onPressed: () {
                                             if (widget.userId == null) return;
                                             _showBidDialog(context, crop['id'], crop['name'], crop['base_price'].toString());
                                          },
                                          label: const Text("PLACE BID", style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

      // Other Tabs (Inbox, Orders, Profile)
      widget.userId != null ? InboxScreen(userId: widget.userId!) : const Center(child: Text("Error: No User ID")),
      widget.userId != null ? OrdersScreen(userId: widget.userId!) : const Center(child: Text("Error: No User ID")),
      widget.userId != null ? ProfileScreen(userId: widget.userId!) : const Center(child: Text("Error: No User ID")),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Marketplace 🛒"),
              backgroundColor: Colors.blue,
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}