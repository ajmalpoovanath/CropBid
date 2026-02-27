import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../services/api_service.dart';

class CropDetailScreen extends StatefulWidget {
  final dynamic crop; // Passing the crop data object
  final int userId;

  const CropDetailScreen({super.key, required this.crop, required this.userId});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final TextEditingController _bidController = TextEditingController();

  // 🖼️ The Gallery Opener we discussed
  void _openFullGallery(BuildContext context, List<String> images, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    // Assuming 'images' is a list of strings from your Django API
    List<String> images = List<String>.from(widget.crop['images'] ?? [widget.crop['image']]);

    return Scaffold(
      appBar: AppBar(title: Text(widget.crop['name']), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP GALLERY SECTION
            SizedBox(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openFullGallery(context, images, index),
                        child: Image.network(images[index], fit: BoxFit.cover, width: double.infinity),
                      );
                    },
                  ),
                  Positioned(
                    bottom: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: const Text("Tap to Zoom 🔍", style: TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. NAME & PRICE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.crop['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("₹${widget.crop['price']}/kg", style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // 3. QUANTITY & FARMER INFO
                  Text("Available Quantity: ${widget.crop['quantity']} kg", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const Divider(height: 30),

                  // 4. DESCRIPTION
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.crop['description'] ?? "No description provided.", style: const TextStyle(fontSize: 16, height: 1.5)),
                  
                  const SizedBox(height: 40),

                  // 5. BIDDING SECTION
                  const Text("Place Your Bid", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bidController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: "Enter amount", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _placeBid(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25)),
                        child: const Text("SUBMIT BID", style: TextStyle(color: Colors.white)),
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

  void _placeBid() async {
    // We'll link this to your ApiService.placeBid() next!
    print("Bidding ₹${_bidController.text} on ${widget.crop['name']}");
  }
}