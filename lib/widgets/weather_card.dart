import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/weather_data.dart';

/// A card that displays the current weather.
/// Pass real [data] once fetched; while null, shows a loading placeholder.
class WeatherCard extends StatelessWidget {
  final WeatherData? data;
  final bool isLoading;

  const WeatherCard({super.key, this.data, this.isLoading = false});

  IconData get _icon {
    final condition = data?.condition.toLowerCase() ?? '';

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.grain;
    }
    if (condition.contains('snow')) {
      return Icons.ac_unit_outlined;
    }
    if (condition.contains('cloud') || condition.contains('overcast')) {
      return Icons.wb_cloudy_outlined;
    }
    if (condition.contains('sun') || condition.contains('clear')) {
      return Icons.wb_sunny_outlined;
    }

    return Icons.cloud_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final city = data?.city ?? 'Fetching location...';
    final condition = data?.condition ?? '—';
    final temperature = data != null
        ? '${data!.temperature.toStringAsFixed(0)}°C'
        : '--°C';

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
                isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
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
          Icon(_icon, color: Colors.white, size: 64),
        ],
      ),
    );
  }
}
