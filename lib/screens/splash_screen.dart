import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scale = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Navigate to login after the splash has had a moment to breathe.
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.wb_sunny,
                        color: AppColors.coral,
                        size: 64,
                      ),
                      const Positioned(
                        bottom: -6,
                        right: -24,
                        child: Icon(
                          Icons.cloud,
                          color: AppColors.teal,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Weather Wardrobe',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.plum,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dress Smart for Every Weather',
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.plum.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.coral),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
