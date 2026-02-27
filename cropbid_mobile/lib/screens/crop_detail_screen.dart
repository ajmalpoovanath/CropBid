import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../services/api_service.dart';

class CropDetailScreen extends StatefulWidget {
  final dynamic crop; 
  final int userId;

  const CropDetailScreen({super.key, required this.crop, required this.userId});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final TextEditingController _bidController = TextEditingController();
  bool _isSubmitting = false;

  // 🖼️ Helper to get the correct Image URL dynamically
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    // Cleans up the localhost/127.0.0.1 switching issues
    return "${ApiService.baseUrl.replaceAll('/api', '')}$path";
  }

  // 🔍 THE FIX: Mapping the list of objects into a list of image strings
  List<String> _getGalleryList() {
    List<String> gallery = [];
    
    // 1. Add the main thumbnail first
    if (widget.crop['image'] != null) {
      gallery.add(_getImageUrl(widget.crop['image']));
    }
    
    // 2. Loop through the 'images' list of objects and extract the 'image' string
    if (widget.crop['images'] != null && widget.crop['images'] is List) {
      for (var item in widget.crop['images']) {
        if (item is Map && item.containsKey('image')) {
          gallery.add(_getImageUrl(item['image']));
        }
      }
    }
    
    // 3. Remove duplicates (in case thumbnail is also in gallery list)
    return gallery.toSet().toList();
  }

  void _openFullGallery(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0),
          body: PhotoViewGallery.builder(
            itemCount: images.length,
            pageController: PageController(initialPage: index),
            builder: (context, i) => PhotoViewGalleryPageOptions(
              imageProvider: NetworkImage(images[i]),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
            ),
            scrollPhysics: const BouncingScrollPhysics(),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Future<void> _placeBid() async {
    final String amount = _bidController.text.trim();
    if (amount.isEmpty) return;

    setState(() => _isSubmitting = true);

    final success = await ApiService.placeBid(
      widget.userId, 
      widget.crop['id'], 
      amount
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bid Placed Successfully! 🚀"), backgroundColor: Colors.green)
        );
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to place bid. Try again."), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = _getGalleryList();
    // Use base_price from your Serializer to avoid the null error
    final String price = widget.crop['base_price']?.toString() ?? "0.0";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.crop['name']), 
        backgroundColor: Colors.white, 
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP GALLERY SECTION
            SizedBox(
              height: 350,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openFullGallery(context, images, index),
                        child: Image.network(
                          images[index], 
                          fit: BoxFit.cover, 
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => 
                            const Center(child: Icon(Icons.broken_image, size: 50)),
                        ),
                      );
                    },
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 15, left: 0, right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Text("Swipe to see all ${images.length} photos ↔️", 
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.crop['name'], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Text("₹$price", style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  Text("Total Lot: ${widget.crop['quantity']} kg", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  Text("Farmer: ${widget.crop['farmer_name'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  
                  const Divider(height: 40),

                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(widget.crop['description'] ?? "No description provided.", 
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black54)),
                  
                  const SizedBox(height: 40),

                  const Text("Place Your Bid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bidController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Enter total amount", 
                            prefixText: "₹ ",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _placeBid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, 
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("BID NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}