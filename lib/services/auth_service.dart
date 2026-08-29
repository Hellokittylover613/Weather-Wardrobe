import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://192.168.1.142:8000';

  // This is the MySQL ID belonging to the currently logged-in Firebase user.
  static int? mysqlUserId;

  // Sync Firebase user with our MySQL database.
  static Future<int> syncFirebaseUser() async {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      throw Exception('No Firebase user is currently logged in.');
    }

    final String uid = firebaseUser.uid;
    final String email = firebaseUser.email ?? '';

    String name = firebaseUser.displayName ?? '';

    // If Firebase doesn't have a display name,
    // use the part before @ in the email.
    if (name.trim().isEmpty && email.isNotEmpty) {
      name = email.split('@').first;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/firebase-users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'firebase_uid': uid, 'email': email, 'name': name}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync Firebase user: ${response.body}');
    }

    final data = jsonDecode(response.body);

    if (data['status'] != 'success') {
      throw Exception(data['message'] ?? 'Failed to sync Firebase user.');
    }

    final int userId = data['user_id'];

    mysqlUserId = userId;

    print('========================================');
    print('FIREBASE USER SYNCED WITH MYSQL');
    print('Firebase UID: $uid');
    print('Email: $email');
    print('MySQL User ID: $userId');
    print('========================================');

    return userId;
  }
}
