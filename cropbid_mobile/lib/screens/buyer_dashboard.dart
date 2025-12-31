import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  List<dynamic> _marketCrops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMarketplace();
  }

  Future<void> _loadMarketplace() async {
    final crops = await ApiService.getAllCrops();
    setState(() {
      _marketCrops = crops;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: _isLoading
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
                            // 1. Crop Image
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
                            
                            // 2. Details
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
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                      onPressed: () {
                                        // TODO: Open Bidding Screen
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Bidding Coming Soon!"))
                                        );
                                      },
                                      child: const Text("PLACE BID", style: TextStyle(color: Colors.white)),
                                    ),
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
    );
  }
}