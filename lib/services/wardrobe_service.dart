import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class WardrobeService {
  static const String baseUrl = 'http://192.168.1.142:8000';

  // ============================================================
  // CURRENT FIREBASE USER
  // ============================================================

  User? get currentFirebaseUser {
    return FirebaseAuth.instance.currentUser;
  }

  // ============================================================
  // BUILD IMAGE URL
  // ============================================================

  String buildImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) {
      return '';
    }

    final String path = imagePath.trim();

    // Already a complete URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Backend normally returns:
    // /uploads/example.png
    //
    // We want:
    // http://192.168.1.142:8000/uploads/example.png

    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }

    return '$baseUrl/$path';
  }

  // ============================================================
  // GET MYSQL USER ID FROM FIREBASE UID
  // ============================================================

  Future<int> getMySqlUserId() async {
    final User? user = currentFirebaseUser;

    if (user == null) {
      throw Exception('No Firebase user is currently logged in.');
    }

    final String firebaseUid = user.uid;
    final String? email = user.email;

    if (firebaseUid.isEmpty) {
      throw Exception('Firebase UID is missing.');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/firebase-users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_uid': firebaseUid, 'email': email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not sync Firebase user.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    final dynamic data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      final dynamic userId = data['user_id'];

      if (userId != null) {
        return int.parse(userId.toString());
      }
    }

    throw Exception(
      'Backend did not return a MySQL user ID.\n'
      'Response: ${response.body}',
    );
  }

  // ============================================================
  // UPLOAD IMAGE
  // ============================================================

  Future<String> uploadImage(Uint8List imageBytes, String filename) async {
    final uri = Uri.parse('$baseUrl/upload-image');

    final request = http.MultipartRequest('POST', uri);

    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
    );

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Image upload failed.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    final dynamic data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      final dynamic imageUrl = data['image_url'] ?? data['url'];

      if (imageUrl != null) {
        final String url = imageUrl.toString();

        print('UPLOAD IMAGE URL: $url');

        return url;
      }
    }

    throw Exception(
      'Upload succeeded but no image URL was returned.\n'
      'Response: ${response.body}',
    );
  }

  // ============================================================
  // REMOVE BACKGROUND
  // ============================================================

  Future<String> removeBackground(String filename) async {
    final response = await http.post(
      Uri.parse('$baseUrl/remove-background'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'filename': filename}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Background removal failed.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    final dynamic data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      final dynamic imageUrl = data['image_url'] ?? data['url'];

      if (imageUrl != null) {
        final String url = imageUrl.toString();

        print('BACKGROUND REMOVED IMAGE URL: $url');

        return url;
      }
    }

    throw Exception(
      'Background removal succeeded but no image URL was returned.\n'
      'Response: ${response.body}',
    );
  }

  // ============================================================
  // CREATE WARDROBE ITEM
  // ============================================================

  Future<void> createWardrobeItem({
    required String name,
    required String category,
    required String weather,
    required String occasion,
    String? color,
    required String imageUrl,
  }) async {
    final int userId = await getMySqlUserId();

    final response = await http.post(
      Uri.parse('$baseUrl/wardrobe-items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'category': category,
        'color': color,
        'weather': weather,
        'occasion': occasion,
        'image_url': imageUrl,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not create wardrobe item.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    print('WARDROBE ITEM CREATED: ${response.body}');
  }

  // ============================================================
  // GET WARDROBE ITEMS
  // ============================================================

  Future<List<dynamic>> getWardrobeItems() async {
    final int userId = await getMySqlUserId();

    final response = await http.get(
      Uri.parse('$baseUrl/wardrobe-items?user_id=$userId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not load wardrobe items.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    final dynamic data = jsonDecode(response.body);

    if (data is Map<String, dynamic>) {
      final dynamic items = data['items'];

      if (items is List) {
        print('LOADED ${items.length} WARDROBE ITEMS');

        return items;
      }
    }

    if (data is List) {
      return data;
    }

    throw Exception(
      'Unexpected wardrobe response.\n'
      'Response: ${response.body}',
    );
  }

  // ============================================================
  // UPDATE WARDROBE ITEM
  // ============================================================

  Future<void> updateWardrobeItem({
    required int itemId,
    required String name,
    required String category,
    required String weather,
    required String occasion,
    String? color,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> body = {
      'name': name,
      'category': category,
      'weather': weather,
      'occasion': occasion,
    };

    if (color != null) {
      body['color'] = color;
    }

    if (imageUrl != null) {
      body['image_url'] = imageUrl;
    }

    final response = await http.put(
      Uri.parse('$baseUrl/wardrobe-items/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not update wardrobe item.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    print('WARDROBE ITEM UPDATED: ${response.body}');
  }

  // ============================================================
  // DELETE WARDROBE ITEM
  // ============================================================

  Future<void> deleteWardrobeItem(int itemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/wardrobe-items/$itemId'),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Could not delete wardrobe item.\n'
        'Status: ${response.statusCode}\n'
        'Response: ${response.body}',
      );
    }

    print('WARDROBE ITEM DELETED: $itemId');
  }
}
