import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // Use localhost for iOS Simulator.
  // Change to your Mac's IP (e.g., 192.168.1.5) for real Android/iPhone testing.
  static const String baseUrl = "http://localhost:8000/api";

  // --- AUTH & PROFILE ---

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/login/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {"success": false, "message": "Invalid Credentials"};
    } catch (e) {
      return {"success": false, "message": "Connection Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String password,
    String email,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/register/');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "email": email,
          "role": role,
        }),
      );
      return response.statusCode == 201
          ? {"success": true}
          : {"success": false, "message": response.body};
    } catch (e) {
      return {"success": false, "message": "Error: $e"};
    }
  }

  static Future<Map<String, dynamic>> getProfile(int userId) async {
    final url = Uri.parse('$baseUrl/update_profile/?user_id=$userId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {"success": false};
    } catch (e) {
      return {"success": false};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String role,
    required String address,
    required String phone,
    required double lat,
    required double lng,
    String? fullName,
    String? companyName,
    String? licenseNumber,
    String? imagePath,
  }) async {
    final url = Uri.parse('$baseUrl/update_profile/');
    try {
      var request = http.MultipartRequest('POST', url);
      request.fields.addAll({
        'user_id': userId.toString(),
        'role': role,
        'phone': phone,
        'address': address,
        'latitude': lat.toString(),
        'longitude': lng.toString(),
      });
      if (fullName != null) request.fields['full_name'] = fullName;
      if (companyName != null) request.fields['company_name'] = companyName;
      if (licenseNumber != null)
        request.fields['license_number'] = licenseNumber;

      if (imagePath != null) {
        File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'profile_picture',
              await imageFile.readAsBytes(),
              filename: basename(imagePath),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200
          ? {"success": true}
          : {"success": false};
    } catch (e) {
      return {"success": false};
    }
  }

  // --- MARKET & CROPS ---

  static Future<List<dynamic>> getAllCrops() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market/crops/'));
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMyCrops(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/market/crops/?user_id=$userId'),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addCrop({
    required int userId,
    required String name,
    required String description,
    required String price,
    required String quantity,
    required List<File> imageFiles,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/market/crops/'),
      );
      request.fields.addAll({
        'user_id': userId.toString(),
        'name': name,
        'description': description,
        'base_price': price,
        'quantity': quantity,
      });

      for (var file in imageFiles) {
        if (await file.exists()) {
          List<int> bytes = await file.readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'images',
              bytes,
              filename: basename(file.path),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 201
          ? {"success": true, "message": "Crop Added Successfully!"}
          : {"success": false, "message": response.body};
    } catch (e) {
      return {"success": false, "message": "Flutter Error: $e"};
    }
  }

  // --- CHAT & INBOX ---

  static Future<List<dynamic>> getInbox(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/communication/inbox/?user_id=$userId'),
      );
      return response.statusCode == 200
          ? List<dynamic>.from(jsonDecode(response.body))
          : [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getMessages(int userId, int otherId) async {
    try {
      final url =
          '$baseUrl/communication/chat/?user_id=$userId&other_id=$otherId';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      debugPrint("Network Error in getMessages: $e");
    }
    return [];
  }

  static Future<bool> sendMessage(
    int senderId,
    int receiverId,
    String message,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/communication/chat/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': senderId,
          'receiver': receiverId,
          'message': message.trim(),
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- BIDS, ORDERS & PAYMENTS ---

  static Future<bool> placeBid(int userId, int cropId, String amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/market/bid/place/'),
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

  static Future<List<dynamic>> getBidsForCrop(int cropId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/market/bid/list/$cropId/'),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> updateBidStatus(int bidId, String action) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/market/bid/update/$bidId/'),
        headers: {'Content-Type': 'application/json'},
        // 🔑 THE FIX: Uppercase 'action' ensures Django recognizes 'ACCEPTED' or 'REJECTED'
        body: jsonEncode({'action': action.toUpperCase()}),
      );
      if (response.statusCode != 200) {
        debugPrint(
          "BID UPDATE ERROR: ${response.statusCode} - ${response.body}",
        );
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("BID UPDATE EXCEPTION: $e");
      return false;
    }
  }

  static Future<List<dynamic>> getOrders(int userId) async {
    try {
      // 📡 FIXED URL: Matches your Django 'market/urls.py'
      final response = await http.get(
        Uri.parse("$baseUrl/market/orders/list/?user_id=$userId"),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<bool> makePayment(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/market/payment/pay/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'order_id': orderId}),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updateOrderStatus(int orderId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/market/orders/update/$orderId/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> saveDeviceToken(int userId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/save-token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'token': token}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
