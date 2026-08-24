import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// A card that displays the current weather.
/// Takes plain values for now — swap these for real API data in Day 3+.
class WeatherCard extends StatelessWidget {
  final String city;
  final String condition;
  final String temperature; // e.g. "24°C"
  final IconData icon;

  const WeatherCard({
    super.key,
    this.city = 'Karachi',
    this.condition = 'Partly Cloudy',
    this.temperature = '24°C',
    this.icon = Icons.wb_cloudy_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, AppColors.teal.withOpacity(0.75)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  city,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  condition,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  temperature,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, color: Colors.white, size: 64),
        ],
      ),
    );
  }
}
