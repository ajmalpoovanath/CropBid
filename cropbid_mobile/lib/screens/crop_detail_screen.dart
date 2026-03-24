import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class CropDetailScreen extends StatefulWidget {
  final Map<String, dynamic> crop;
  final int userId;

  const CropDetailScreen({super.key, required this.crop, required this.userId});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    return "${ApiService.baseUrl.replaceAll('/api', '')}$path";
  }

  void _startChat() {
    final dynamic userObj = widget.crop['user'];
    final int? correctLoginId = int.tryParse(
      (userObj is Map ? userObj['id'] : userObj).toString(),
    );

    final String ownerName =
        (userObj is Map ? userObj['username'] : null) ??
        widget.crop['farmer_name'] ??
        "Farmer";

    if (correctLoginId == null || correctLoginId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Could not find Farmer's Login ID"),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: '/chat/$correctLoginId'),
        builder: (context) => ChatScreen(
          key: ValueKey(correctLoginId),
          userId: widget.userId,
          otherId: correctLoginId,
          otherName: ownerName,
        ),
      ),
    );
  }

  void _showBidDialog() {
    // 🛠️ Extract base price for validation
    final double basePrice =
        double.tryParse(widget.crop['base_price']?.toString() ?? "0.0") ?? 0.0;
    final double highestBid =
        double.tryParse(widget.crop['highest_bid']?.toString() ?? "0.0") ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => _AddBidDialog(
        basePrice: basePrice,
        highestBid: highestBid,
        onBidPlaced: (amount) async {
          final success = await ApiService.placeBid(
            widget.userId,
            widget.crop['id'],
            amount,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? "Bid Placed! 🔨"
                      : "Bid Failed: Check Minimum Price",
                ),
                backgroundColor: success
                    ? AppTheme.paddyGreen
                    : AppTheme.clayRed,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    List<dynamic> rawImages = [];
    if (crop['images'] is List) {
      rawImages = crop['images'];
    } else if (crop['image'] != null) {
      rawImages = [crop['image']];
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppTheme.backgroundForest,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  rawImages.isEmpty
                      ? const Center(
                          child: Icon(
                            Icons.agriculture,
                            size: 100,
                            color: AppTheme.paddyGreen,
                          ),
                        )
                      : PageView.builder(
                          controller: _pageController,
                          itemCount: rawImages.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) {
                            final dynamic data = rawImages[index];
                            final String path = data is Map
                                ? (data['image'] ?? "")
                                : data.toString();
                            return Image.network(
                              _getImageUrl(path),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                color: AppTheme.surfaceMoss,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.white12,
                                ),
                              ),
                            );
                          },
                        ),
                  if (rawImages.length > 1)
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(rawImages.length, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? AppTheme.paddyGreen
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          crop['name'] ?? "Unnamed Crop",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        "₹${crop['base_price']}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.paddyGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${crop['quantity']} kg available",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const Divider(height: 40, color: Colors.white10),
                  const Text(
                    "Description",
                    style: TextStyle(
                      color: AppTheme.paddyGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    crop['description'] ?? "No description provided.",
                    style: const TextStyle(color: Colors.white60, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  _buildBidInfo(crop),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        color: AppTheme.surfaceMoss,
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundForest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppTheme.paddyGreen,
                  ),
                  onPressed: _startChat,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _showBidDialog,
                    child: const Text(
                      "PLACE BID NOW",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBidInfo(Map<String, dynamic> crop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMoss,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Highest Bid", style: TextStyle(color: Colors.white70)),
              Text(
                "Live Auction",
                style: TextStyle(
                  color: AppTheme.clayRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Text(
            "₹${crop['highest_bid'] ?? '0.0'}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddBidDialog extends StatefulWidget {
  final double basePrice;
  final double highestBid;
  final Function(String) onBidPlaced;

  const _AddBidDialog({
    required this.basePrice,
    required this.highestBid,
    required this.onBidPlaced,
  });

  @override
  State<_AddBidDialog> createState() => _AddBidDialogState();
}

class _AddBidDialogState extends State<_AddBidDialog> {
  final _controller = TextEditingController();

  void _validateAndSubmit() {
    final double enteredAmount = double.tryParse(_controller.text) ?? 0.0;

    // 🛡️ FRONTEND RESTRICTION
    if (enteredAmount < widget.basePrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bid must be at least ₹${widget.basePrice}"),
          backgroundColor: AppTheme.clayRed,
        ),
      );
      return;
    }

    widget.onBidPlaced(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceMoss,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        "Place Your Bid",
        style: TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        autofocus: true,
        decoration: InputDecoration(
          // 💡 Hint clearly shows the required base price
          hintText: "Min bid: ₹${widget.basePrice}",
          hintStyle: const TextStyle(color: Colors.white38),
          prefixText: "₹ ",
          prefixStyle: const TextStyle(color: AppTheme.paddyGreen),
          filled: true,
          fillColor: AppTheme.backgroundForest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: _validateAndSubmit, // 👈 Triggers validation logic
          child: const Text("PLACE BID"),
        ),
      ],
    );
  }
}
