import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  final int userId;
  final bool isFarmer;

  const OrdersScreen({super.key, required this.userId, this.isFarmer = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    // 🛠️ THE FIX: Match the method name in your ApiService
    final orders = await ApiService.getOrders(widget.userId);
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: AppBar(
        title: const Text(
          "Order History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.paddyGreen),
            )
          : RefreshIndicator(
              onRefresh: _fetchOrders,
              color: AppTheme.paddyGreen,
              child: _orders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final status =
                            order['status']?.toString().toUpperCase() ??
                            'PENDING';

                        // 🔑 THE FIX: Map to the correct JSON keys from Django
                        final String cropName =
                            order['crop_name'] ?? "Unknown Crop";
                        final String quantity =
                            order['crop_quantity']?.toString() ?? "0";
                        final String amount =
                            order['amount']?.toString() ?? "0";
                        final String otherParty =
                            order['other_party_name'] ?? "";

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          color: AppTheme.surfaceMoss,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Order #${order['id']}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  cropName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (otherParty.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    otherParty,
                                    style: const TextStyle(
                                      color: AppTheme.paddyGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  "Quantity: $quantity kg",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 24,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total Amount",
                                      style: TextStyle(color: Colors.white60),
                                    ),
                                    Text(
                                      "₹$amount",
                                      style: const TextStyle(
                                        color: AppTheme.paddyGreen,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),

                                // 💳 Conditional Payment Button for Buyers
                                if (!widget.isFarmer &&
                                    status == 'PENDING_PAYMENT')
                                  _buildPayButton(order['id']),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "No orders found yet.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(int orderId) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.paddyGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            // Trigger payment logic
            final success = await ApiService.makePayment(orderId);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment Successful! ✅"),
                  backgroundColor: AppTheme.paddyGreen,
                ),
              );
              _fetchOrders(); // Refresh list
            }
          },
          child: const Text(
            "PAY NOW",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'CONFIRMED':
      case 'PAID':
      case 'DELIVERED':
        color = AppTheme.paddyGreen;
        break;
      case 'CANCELLED':
        color = AppTheme.clayRed;
        break;
      case 'PENDING_PAYMENT':
        color = Colors.orangeAccent;
        break;
      default:
        color = Colors.white38;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
