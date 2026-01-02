import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ViewBidsScreen extends StatefulWidget {
  final int cropId;
  final String cropName;

  const ViewBidsScreen({super.key, required this.cropId, required this.cropName});

  @override
  State<ViewBidsScreen> createState() => _ViewBidsScreenState();
}

class _ViewBidsScreenState extends State<ViewBidsScreen> {
  List<dynamic> _bids = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBids();
  }

  Future<void> _loadBids() async {
    final bids = await ApiService.getBidsForCrop(widget.cropId);
    if (mounted) {
      setState(() {
        _bids = bids;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(int bidId, String action) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating...")));
    
    final success = await ApiService.updateBidStatus(bidId, action);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bid $action!")));
      _loadBids(); // Refresh list to show new status
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bids for ${widget.cropName}"),
        backgroundColor: Colors.green,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bids.isEmpty
              ? const Center(child: Text("No bids received yet."))
              : ListView.builder(
                  itemCount: _bids.length,
                  itemBuilder: (context, index) {
                    final bid = _bids[index];
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Bidder Name & Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bid['buyer_name'] ?? "Unknown Buyer",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "₹${bid['amount']}",
                                  style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            
                            // 2. Status Badge
                            Row(
                              children: [
                                const Text("Status: "),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: bid['status'] == 'ACCEPTED' ? Colors.green[100] 
                                         : bid['status'] == 'REJECTED' ? Colors.red[100] 
                                         : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    bid['status'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: bid['status'] == 'ACCEPTED' ? Colors.green 
                                           : bid['status'] == 'REJECTED' ? Colors.red 
                                           : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // 3. Action Buttons (Only show if PENDING)
                            if (bid['status'] == 'PENDING')
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _updateStatus(bid['id'], 'REJECTED'),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text("REJECT"),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _updateStatus(bid['id'], 'ACCEPTED'),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text("ACCEPT", style: TextStyle(color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}