import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final data = await ApiService.getOrders(widget.userId);
    if (mounted) {
      setState(() {
        _orders = data;
        _isLoading = false;
      });
    }
  }

  // Buyer: Pay for Order
  Future<void> _processPayment(int orderId, double amount) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Payment"),
        content: Text("Pay ₹$amount via UPI?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("PAY NOW")),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Processing Payment...")));
    final success = await ApiService.makePayment(orderId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Paid Successfully! ✅")));
      _loadOrders();
    }
  }

  // Farmer: Mark as Delivered
  Future<void> _markAsDelivered(int orderId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delivery"),
        content: const Text("Mark this order as Delivered? This will move it to History."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("CONFIRM")),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    final success = await ApiService.updateOrderStatus(orderId, 'DELIVERED');
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Delivered! 🚚")));
      _loadOrders();
    }
  }

  // Helper to build the list
  Widget _buildOrderList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text("No orders here.", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isPending = order['status'] == 'PENDING_PAYMENT';
        final isPaid = order['status'] == 'CONFIRMED' || order['payment_status'] == 'PAID';
        final isDelivered = order['status'] == 'DELIVERED';

        return Card(
          margin: const EdgeInsets.all(10),
          elevation: 3,
          child: Column(
            children: [
              ListTile(
                leading: order['crop_image'] != null
                    ? Image.network("http://127.0.0.1:8000${order['crop_image']}", width: 50, fit: BoxFit.cover)
                    : const Icon(Icons.shopping_bag),
                title: Text(order['crop_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['other_party_name'], style: const TextStyle(fontSize: 12)),
                    Text("Amount: ₹${order['amount']}", style: const TextStyle(color: Colors.green)),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    isDelivered ? "DELIVERED" : (isPaid ? "PAID" : "PENDING"),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  backgroundColor: isDelivered ? Colors.grey : (isPaid ? Colors.green : Colors.orange),
                ),
              ),
              
              // BUTTONS
              if (!isDelivered) 
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: widget.isFarmer
                        ? (isPaid 
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.local_shipping, color: Colors.white),
                                label: const Text("MARK AS DELIVERED", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                                onPressed: () => _markAsDelivered(order['id']),
                              )
                            : const Text("Waiting for Buyer Payment...", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
                        : (isPending 
                            ? ElevatedButton.icon(
                                icon: const Icon(Icons.payment, color: Colors.white),
                                label: const Text("PAY NOW", style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                onPressed: () => _processPayment(order['id'], double.parse(order['amount'].toString())),
                              )
                            : const Text("Waiting for Delivery 🚚", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey))),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Separate Orders into Active vs History
    final activeOrders = _orders.where((o) => ['PENDING_PAYMENT', 'CONFIRMED', 'SHIPPED'].contains(o['status'])).toList();
    final historyOrders = _orders.where((o) => ['DELIVERED', 'CANCELLED'].contains(o['status'])).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Orders 📦"),
          backgroundColor: widget.isFarmer ? Colors.green : Colors.indigo,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Active Orders"),
              Tab(text: "Order History"), // <--- Older orders go here
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildOrderList(activeOrders),
                  _buildOrderList(historyOrders),
                ],
              ),
      ),
    );
  }
}