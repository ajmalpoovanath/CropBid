import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart'; 
import 'chat_screen.dart'; 
import 'inbox_screen.dart'; 

class BuyerDashboard extends StatefulWidget {
  final int? userId; 

  const BuyerDashboard({super.key, this.userId});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  // 0 = Market, 1 = Inbox, 2 = Profile
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

  // 👇 UPDATED: Function to show the Bid Dialog with Minimum Price Logic
  void _showBidDialog(BuildContext context, int cropId, String cropName, String basePriceString) {
    final TextEditingController _amountController = TextEditingController();
    
    // Parse the base price to a number safely
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
              // Show the minimum required amount
              Text(
                "Minimum Bid: ₹$basePriceString", 
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
              ),
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

                // 🛑 LOGIC CHECK: Is offer less than base price?
                if (offer < basePrice) {
                  // Close the keyboard if open
                  FocusScope.of(context).unfocus();
                  
                  // Show Error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Offer too low! Minimum is ₹$basePrice"),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return; // Stop here! Don't call API.
                }

                Navigator.pop(context); // Close dialog
                
                // Show loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Placing Bid...")),
                );

                // Call the API
                final success = await ApiService.placeBid(widget.userId!, cropId, amountText);

                if (mounted) {
                   if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bid Placed Successfully! 💵")),
                      );
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
    // Define the Pages
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
                                  const SizedBox(height: 5),
                                  Text("Quantity: ${crop['quantity']} kg available"),
                                  const SizedBox(height: 15),
                                  
                                  // Two Buttons (Chat & Bid)
                                  Row(
                                    children: [
                                      // 1. CHAT BUTTON
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
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            side: const BorderSide(color: Colors.blue),
                                          ),
                                          child: const Text("CHAT"),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      
                                      // 2. BID BUTTON
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                          onPressed: () {
                                             if (widget.userId == null) {
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please Login First")));
                                                return;
                                             }
                                             // 👇 PASS THE BASE PRICE HERE
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

      // TAB 2: PROFILE
      widget.userId != null 
          ? ProfileScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),
    ];

    return Scaffold(
      // Only show AppBar on Home (Tab 0)
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
          : null, // Inbox and Profile have their own AppBars
      
      body: _pages[_selectedIndex],
      
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message), 
            label: 'Chats',
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