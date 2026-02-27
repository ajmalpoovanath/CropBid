import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AddCropScreen extends StatefulWidget {
  final int userId;
  const AddCropScreen({super.key, required this.userId});

  @override
  State<AddCropScreen> createState() => _AddCropScreenState();
}

class _AddCropScreenState extends State<AddCropScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  
  // 1. Changed to a List to handle multiple photos
  List<File> _imageFiles = []; 
  bool _isLoading = false;

  // 2. Updated to pick multiple images at once
  Future<void> _pickMultiImages() async {
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage();
    
    if (pickedList.isNotEmpty) {
      setState(() {
        _imageFiles.addAll(pickedList.map((xFile) => File(xFile.path)).toList());
      });
    }
  }

  // 3. Helper to remove a specific image if the farmer changes their mind
  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  void _submitCrop() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Name and Price are required")));
      return;
    }

    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please add at least one image of your crop")));
      return;
    }

    setState(() => _isLoading = true);

    // 4. Passing the list of images to the ApiService
    final result = await ApiService.addCrop(
      userId: widget.userId,
      name: _nameController.text,
      description: _descController.text,
      price: _priceController.text,
      quantity: _qtyController.text,
      imageFiles: _imageFiles, // We will update ApiService to accept this List
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Crop Listed Successfully! 🌾")));
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${result['message']}")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Crop"), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Crop Images", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // 5. Professional Multi-Image Preview Row
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageFiles.length + 1,
                itemBuilder: (context, index) {
                  if (index == _imageFiles.length) {
                    // "Add More" Button at the end of the list
                    return GestureDetector(
                      onTap: _pickMultiImages,
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    );
                  }
                  
                  return Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: FileImage(_imageFiles[index]), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 25),
            
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Crop Name (e.g. Potato)", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            
            Row(
              children: [
                Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price (₹)", border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _qtyController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty (kg)", border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCrop,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("LIST CROP", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}