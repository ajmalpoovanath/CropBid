import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; 
import 'chat_screen.dart'; 
import 'inbox_screen.dart'; 
import 'orders_screen.dart'; // <--- 1. IMPORT THIS

class BuyerDashboard extends StatefulWidget {
  final int? userId; 

  const BuyerDashboard({super.key, this.userId});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  // 0 = Market, 1 = Inbox, 2 = Orders, 3 = Profile
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

  // 👇 2. NEW: Helper to calculate Time Left
  String _calculateTimeLeft(String? endTime) {
    if (endTime == null) return "Auction Not Started";
    final end = DateTime.parse(endTime);
    final now = DateTime.now().toUtc(); // Use UTC to match server typically
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bid Placed! Timer Started ⏱️")),
                      );
                      _loadMarketplace(); // <--- 3. REFRESH to show new Highest Bid
                   } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to place bid. Try again.")),
                      );
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
      // TAB 0: MARKETPLACE
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
                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
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
                            // Details
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
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        "₹${crop['base_price']}/kg",
                                        style: const TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // 👇 4. NEW: HIGHEST BID & TIMER INFO
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Highest: ₹${crop['highest_bid']}", 
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                                      ),
                                      Text(
                                        crop['auction_end_time'] != null ? "Active ⏱️" : "No Bids", 
                                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)
                                      ),
                                    ],
                                  ),
                                  // Show exact time left
                                  if (crop['auction_end_time'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        _calculateTimeLeft(crop['auction_end_time']),
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ),

                                  const SizedBox(height: 15),
                                  
                                  // Two Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            if (widget.userId == null) {
                                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Login First")));
                                               return;
                                            }
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
                                          child: const Text("CHAT"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                          onPressed: () {
                                             if (widget.userId == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Login First")));
                                                return;
                                             }
                                             _showBidDialog(
                                                context, 
                                                crop['id'], 
                                                crop['name'], 
                                                crop['base_price'].toString()
                                             );
                                          },
                                          child: const Text("PLACE BID", style: TextStyle(color: Colors.white)),
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

      // TAB 1: INBOX
      widget.userId != null 
          ? InboxScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),

      // TAB 2: ORDERS (NEW)
      widget.userId != null 
          ? OrdersScreen(userId: widget.userId!) // <--- 5. Added OrdersScreen
          : const Center(child: Text("Error: No User ID")),

      // TAB 3: PROFILE
      widget.userId != null 
          ? ProfileScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Marketplace 🛒"),
              backgroundColor: Colors.blue,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => const LoginScreen())
                  ),
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
        type: BottomNavigationBarType.fixed, // <--- 6. IMPORTANT for 4 items
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message), 
            label: 'Chats',
          ),
          BottomNavigationBarItem( // <--- 7. Added Orders Icon
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