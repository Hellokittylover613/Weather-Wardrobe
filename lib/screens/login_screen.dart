import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import '../utils/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validate fields
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // REAL FIREBASE LOGIN
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync the Firebase account with our MySQL database.
      await AuthService.syncFirebaseUser();

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'user-not-found':
          message = 'No account exists with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect email or password.';
          break;

        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-disabled':
          message = 'This account has been disabled.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;

        default:
          message = 'Login failed. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              // App icon
              const Center(child: Icon(Icons.checkroom, size: 70)),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Weather Wardrobe',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 10),

              const Center(
                child: Text(
                  'Dress for the weather. Look your best.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 50),

              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Log in to continue to your wardrobe.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // Email
              const Text(
                'Email',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Password
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Sign up
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.signup);
                  },
                  child: const Text("Don't have an account? Sign Up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
