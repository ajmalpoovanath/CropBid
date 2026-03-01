import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ViewBidsScreen extends StatefulWidget {
  final int cropId;
  final String cropName;

  const ViewBidsScreen({
    super.key,
    required this.cropId,
    required this.cropName,
  });

  @override
  State<ViewBidsScreen> createState() => _ViewBidsScreenState();
}

class _ViewBidsScreenState extends State<ViewBidsScreen> {
  List<dynamic> _bids = [];
  bool _isLoading = true;
  bool _anyBidAccepted = false; // 🛠️ Track if we need to refresh the dashboard

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
    // 🛠️ Show themed SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Processing ${action.toLowerCase()}..."),
        backgroundColor: AppTheme.surfaceMoss,
        duration: const Duration(seconds: 1),
      ),
    );

    final success = await ApiService.updateBidStatus(bidId, action);

    if (success && mounted) {
      if (action == 'ACCEPTED') _anyBidAccepted = true;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bid $action successfully! ✅"),
          backgroundColor: action == 'ACCEPTED'
              ? AppTheme.paddyGreen
              : AppTheme.clayRed,
        ),
      );
      _loadBids();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update status ❌"),
          backgroundColor: AppTheme.clayRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 🛠️ Returns 'true' to FarmerDashboard so it knows to refresh the crop list
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _anyBidAccepted) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundForest,
        appBar: AppBar(
          title: Text(
            widget.cropName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _anyBidAccepted),
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.paddyGreen),
              )
            : RefreshIndicator(
                onRefresh: _loadBids,
                color: AppTheme.paddyGreen,
                child: _bids.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bids.length,
                        itemBuilder: (context, index) {
                          final bid = _bids[index];
                          final status = bid['status'] ?? 'PENDING';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: AppTheme.surfaceMoss,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            bid['buyer_name'] ??
                                                "Unknown Buyer",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      Text(
                                        "₹${bid['amount']}",
                                        style: const TextStyle(
                                          fontSize: 22,
                                          color: AppTheme.paddyGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (status == 'PENDING') ...[
                                    const Divider(
                                      color: Colors.white10,
                                      height: 32,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _updateStatus(
                                              bid['id'],
                                              'REJECTED',
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: AppTheme.clayRed,
                                              ),
                                              foregroundColor: AppTheme.clayRed,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: const Text(
                                              "REJECT",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _updateStatus(
                                              bid['id'],
                                              'ACCEPTED',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppTheme.paddyGreen,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                            ),
                                            child: const Text(
                                              "ACCEPT",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.gavel_rounded, size: 80, color: Colors.white10),
          SizedBox(height: 16),
          Text(
            "No bids received yet.",
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'ACCEPTED') color = AppTheme.paddyGreen;
    if (status == 'REJECTED') color = AppTheme.clayRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
