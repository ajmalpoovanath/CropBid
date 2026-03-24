import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AddCropScreen extends StatefulWidget {
  final int userId;
  const AddCropScreen({super.key, required this.userId});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  // 📸 Picking Multiple Images
  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        // 🛠️ FIX: Converting XFile to a permanent File reference immediately
        _images.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  // 🚀 Submitting the Crop
  void _submitCrop() async {
    if (_nameController.text.isEmpty || _images.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name, Price, and at least one Image are required 🌿"),
          backgroundColor: AppTheme.clayRed,
        )
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // 🛠️ FIX: Using the bytes-based ApiService method we updated earlier
      final response = await ApiService.addCrop(
        userId: widget.userId,
        name: _nameController.text,
        description: _descController.text,
        price: _priceController.text,
        quantity: _qtyController.text,
        imageFiles: _images,
      );

      if (mounted) {
        setState(() => _isUploading = false);
        if (response['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Crop Listed Successfully! 🚀"), backgroundColor: AppTheme.paddyGreen)
          );
          Navigator.pop(context, true); 
        } else {
          // 🛠️ FIX: Displaying the actual backend error in a readable way
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload Failed: ${response['message']}"),
              backgroundColor: AppTheme.clayRed,
              duration: const Duration(seconds: 4),
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("System Error: $e"), backgroundColor: AppTheme.clayRed)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundForest,
      appBar: AppBar(
        title: const Text("List New Crop", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📸 Photo Section
            const Text("Crop Images", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.paddyGreen)),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.map((file) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
                          border: Border.all(color: Colors.white10),
                        ),
                      ),
                      Positioned(
                        right: 15, top: 5,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(file)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.clayRed, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 12),
                          ),
                        ),
                      )
                    ],
                  )),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceMoss,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.paddyGreen.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, color: AppTheme.paddyGreen),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 📝 Details Section
            const Text("Product Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.paddyGreen)),
            const SizedBox(height: 16),
            _buildForestField(_nameController, "Crop Name (e.g. Wayanad Ginger)", Icons.eco_outlined),
            const SizedBox(height: 16),
            _buildForestField(_descController, "Description (Harvest date, variety...)", Icons.description_outlined, maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildForestField(_priceController, "Total Price", Icons.currency_rupee, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildForestField(_qtyController, "Qty (kg)", Icons.scale_outlined, keyboardType: TextInputType.number),
                ),
              ],
            ),

            const SizedBox(height: 50),

            // 🔘 Submit Section
            _isUploading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.paddyGreen))
                : ElevatedButton.icon(
                    onPressed: _submitCrop,
                    icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
                    label: const Text("LIST CROP FOR BIDDING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 🌲 Reusable Custom Styled Field
  Widget _buildForestField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppTheme.paddyGreen.withOpacity(0.7)),
        filled: true,
        fillColor: AppTheme.surfaceMoss,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}