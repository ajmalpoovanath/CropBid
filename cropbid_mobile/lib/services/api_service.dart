import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ IMPORTANT: For iOS Simulator, use 127.0.0.1
  // If you switch to Android Emulator later, change this to 10.0.2.2
  static const String baseUrl = "http://localhost:8000/api";

  // The Login Function
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/login/');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        // Success! The server said YES.
        final data = jsonDecode(response.body);
        
        // Save the User ID locally so we remember them
        // We will use this later
        // final prefs = await SharedPreferences.getInstance();
        // await prefs.setInt('user_id', data['id']);
        
        return {"success": true, "data": data};
      } else {
        // Failure! The server said NO.
        return {"success": false, "message": "Invalid Credentials"};
      }
    } catch (e) {
      // Error! Server is down or internet is off.
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // The Registration Function
  static Future<Map<String, dynamic>> register(String username, String password, String email, String role) async {
    final url = Uri.parse('$baseUrl/register/');
    
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "email": email,
          "role": role, // 'FARMER' or 'BUYER'
        }),
      );

      if (response.statusCode == 201) {
        // 201 means "Created" successfully
        return {"success": true, "message": "Account Created!"};
      } else {
        // Validation Error (e.g., username taken)
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  // Update Profile with Image
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String role,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    String? fullName,      // For Farmer
    String? companyName,   // For Buyer
    String? licenseNumber, // For Buyer
    String? imagePath,     // The file path of the photo
  }) async {
    final url = Uri.parse('$baseUrl/update_profile/');
    
    try {
      // 1. Create a Multipart Request
      var request = http.MultipartRequest('POST', url);

      // 2. Add Text Fields
      request.fields['user_id'] = userId.toString();
      request.fields['role'] = role;
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = lng.toString();

      if (fullName != null) request.fields['full_name'] = fullName;
      if (companyName != null) request.fields['company_name'] = companyName;
      if (licenseNumber != null) request.fields['license_number'] = licenseNumber;

      // 3. Add the File (if picked)
      if (imagePath != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture', 
          imagePath
        ));
      }

      // 4. Send it!
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {"success": true, "message": "Profile Updated!"};
      } else {
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // --- MARKETPLACE FUNCTIONS ---

  // 1. Get Farmer's Crops
  static Future<List<dynamic>> getMyCrops(int userId) async {
    final url = Uri.parse('$baseUrl/market/crops/?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body); // Returns a List of crops
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 2. Add New Crop
  static Future<Map<String, dynamic>> addCrop({
    required int userId,
    required String name,
    required String description,
    required String price,
    required String quantity,
    File? imageFile,
  }) async {
    final url = Uri.parse('$baseUrl/market/crops/');
    
    try {
      var request = http.MultipartRequest('POST', url);

      // Add Text Data
      request.fields['user_id'] = userId.toString();
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['base_price'] = price; // Matches Django model field
      request.fields['quantity'] = quantity;
      request.fields['crop_type'] = "Vegetable"; // Hardcoded for now, or add a dropdown later
      request.fields['auction_end_at'] = DateTime.now().add(const Duration(days: 7)).toIso8601String(); // Default 7 days

      // Add Image
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return {"success": true, "message": "Crop Added!"};
      } else {
        return {"success": false, "message": response.body};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // 3. Get ALL Crops (For Marketplace)
  static Future<List<dynamic>> getAllCrops() async {
    // Note: We do NOT pass user_id here, so the backend sends everything
    final url = Uri.parse('$baseUrl/market/crops/'); 
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 4. Get User Profile
  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final url = Uri.parse('$baseUrl/update_profile/?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "message": "Failed to load profile"};
      }
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  // --- CHAT FUNCTIONS ---

  // 1. Get Chat History
  static Future<List<dynamic>> getMessages(int userId, int otherId) async {
    final url = Uri.parse('$baseUrl/communication/chat/?user_id=$userId&other_id=$otherId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 2. Send a Message
  static Future<bool> sendMessage(int senderId, int receiverId, String message) async {
    final url = Uri.parse('$baseUrl/communication/chat/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': senderId,
          'receiver': receiverId,
          'message': message,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 3. Get Inbox (List of Conversations)
  static Future<List<dynamic>> getInbox(int userId) async {
    final url = Uri.parse('$baseUrl/communication/inbox/?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // The API returns a Map of values, we need a List
        // If the backend returns `conversations.values()`, it is already a list.
        return List<dynamic>.from(jsonDecode(response.body));
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // --- BIDDING FUNCTIONS ---

  // 1. Place a Bid (Buyer)
  static Future<bool> placeBid(int userId, int cropId, String amount) async {
    final url = Uri.parse('$baseUrl/market/bid/place/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'crop_id': cropId,
          'amount': amount,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 2. Get Bids for a Crop (For Farmer)
  static Future<List<dynamic>> getBidsForCrop(int cropId) async {
    final url = Uri.parse('$baseUrl/market/bid/list/$cropId/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // 3. Update Bid Status (Accept/Reject)
  static Future<bool> updateBidStatus(int bidId, String action) async {
    final url = Uri.parse('$baseUrl/market/bid/update/$bidId/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'action': action}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> getOrders(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/market/orders/?user_id=$userId'));
    return response.statusCode == 200 ? jsonDecode(response.body) : [];
  }

  static Future<bool> makePayment(int orderId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/market/payment/pay/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'order_id': orderId}),
    );
    return response.statusCode == 201;
  }

  // 3. Update Order Status (For Farmer to mark as Delivered)
  static Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    final url = Uri.parse('$baseUrl/market/orders/update/$orderId/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}