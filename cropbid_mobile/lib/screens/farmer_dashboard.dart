import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Import API
import 'login_screen.dart';
import 'add_crop_screen.dart'; // Import Add Screen

// ⚠️ We need to store the UserID somewhere. 
// For now, let's pass it from Login, or hardcode a "current user" fetch.
// To keep it simple, I'll update the constructor to accept userId.

class FarmerDashboard extends StatefulWidget {
  // Add this parameter so we know WHO is logged in
  // Note: You will need to update LoginScreen to pass this ID!
  final int? userId; 

  const FarmerDashboard({super.key, this.userId});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  List<dynamic> _crops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    // ⚠️ SAFETY CHECK: If userId is null (during testing), use a default or handle error
    if (widget.userId == null) {
      print("Error: No User ID passed to Dashboard");
      return;
    }

    final crops = await ApiService.getMyCrops(widget.userId!);
    setState(() {
      _crops = crops;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Farm 🚜"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
          ),
        ],
      ),
      // FLOATING BUTTON: To Add Crops
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
            if (widget.userId == null) return;
            
            // Wait for result. If true, refresh list.
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => AddCropScreen(userId: widget.userId!))
            );

            if (result == true) {
              _loadCrops(); // Refresh the list!
            }
        },
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : _crops.isEmpty 
              ? const Center(child: Text("No crops listed yet. Click + to add.")) 
              : ListView.builder(
                  itemCount: _crops.length,
                  itemBuilder: (context, index) {
                    final crop = _crops[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: crop['image'] != null 
                            // ⚠️ Note: For Simulator, we might need full URL correction
                            ? Image.network("http://127.0.0.1:8000${crop['image']}", width: 50, height: 50, fit: BoxFit.cover,
                                errorBuilder: (c,e,s) => const Icon(Icons.image_not_supported))
                            : const Icon(Icons.agriculture),
                        title: Text(crop['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Qty: ${crop['quantity']} kg"),
                        trailing: Text("₹${crop['base_price']}", style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
    );
  }
}