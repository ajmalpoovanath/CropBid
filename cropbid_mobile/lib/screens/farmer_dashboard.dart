import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'add_crop_screen.dart';
import 'profile_screen.dart'; 
import 'inbox_screen.dart'; 
import 'view_bids_screen.dart'; // <--- IMPORT VIEW BIDS SCREEN

class FarmerDashboard extends StatefulWidget {
  final int? userId; 

  const FarmerDashboard({super.key, this.userId});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  // 1. Track the active tab 
  // 0 = Home, 1 = Inbox, 2 = Profile
  int _selectedIndex = 0;
  
  // Data for the Home Tab
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

  // 2. Handle Tab Switching
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 3. Define the Views
    final List<Widget> _pages = [
      // TAB 0: THE CROP LIST (Home)
      _isLoadingCrops 
          ? const Center(child: CircularProgressIndicator()) 
          : _crops.isEmpty 
              ? const Center(child: Text("No crops listed yet. Click + to add.")) 
              : ListView.builder(
                  itemCount: _crops.length,
                  itemBuilder: (context, index) {
                    final crop = _crops[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 3,
                      child: Column(
                        children: [
                          // 1. Existing Crop Details
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
                            title: Text(crop['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Qty: ${crop['quantity']} kg"),
                            trailing: Text("₹${crop['base_price']}", style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),

                          // 2. NEW: "VIEW BIDS" Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.gavel, color: Colors.white, size: 18),
                                label: const Text("VIEW BIDS", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () {
                                  // Navigate to the Bids Screen
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
                          ),
                        ],
                      ),
                    );
                  },
                ),
      
      // TAB 1: INBOX SCREEN
      widget.userId != null 
          ? InboxScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),

      // TAB 2: THE PROFILE SCREEN
      widget.userId != null 
          ? ProfileScreen(userId: widget.userId!) 
          : const Center(child: Text("Error: No User ID")),
    ];

    return Scaffold(
      // 4. Conditional AppBar
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

      // 5. The Active Page
      body: _pages[_selectedIndex],

      // 6. Conditional Floating Action Button
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

      // 7. THE BOTTOM NAVIGATION BAR
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
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
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}