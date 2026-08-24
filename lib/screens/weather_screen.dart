import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/weather_card.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import 'location_picker_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  static const List<Map<String, dynamic>> forecast = [
    {'day': 'Mon', 'icon': Icons.wb_sunny_outlined, 'temp': '31°'},
    {'day': 'Tue', 'icon': Icons.wb_cloudy_outlined, 'temp': '33°'},
    {'day': 'Wed', 'icon': Icons.grain, 'temp': '30°'},
    {'day': 'Thu', 'icon': Icons.wb_sunny_outlined, 'temp': '32°'},
    {'day': 'Fri', 'icon': Icons.cloud_outlined, 'temp': '29°'},
  ];

  // ----------------------------------------------------------
  // GET USER'S CURRENT WEATHER
  // ----------------------------------------------------------

  Future<void> _getWeather() async {
    try {
      final position = await LocationService.getCurrentLocation();

      final weather = await WeatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (!mounted) return;

      _showWeatherDialog(weather);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ----------------------------------------------------------
  // OPEN DESTINATION SEARCH
  // ----------------------------------------------------------

  Future<void> _chooseDestination() async {
    final selectedLocation = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (selectedLocation == null) return;

    final latitude = (selectedLocation['lat'] as num).toDouble();

    final longitude = (selectedLocation['lon'] as num).toDouble();

    try {
      final weather = await WeatherService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      _showWeatherDialog(weather);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ----------------------------------------------------------
  // WEATHER POPUP
  // ----------------------------------------------------------

  void _showWeatherDialog(dynamic weather) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(weather.city),
          content: Text(
            'Condition: ${weather.condition}\n'
            'Temperature: '
            '${weather.temperature.toStringAsFixed(1)}°C\n'
            'Feels like: '
            '${weather.feelsLike.toStringAsFixed(1)}°C\n'
            'Humidity: ${weather.humidity}%\n'
            'Wind: '
            '${weather.windSpeed.toStringAsFixed(1)} km/h\n'
            'UV Index: ${weather.uvIndex}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------------
  // SCREEN
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weather',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.plum,
                ),
              ),

              const SizedBox(height: 20),

              const WeatherCard(),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // CURRENT LOCATION BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _getWeather,
                  icon: const Icon(Icons.my_location),
                  label: const Text('GET MY WEATHER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // DESTINATION SEARCH BUTTON
              // ------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _chooseDestination,
                  icon: const Icon(Icons.search),
                  label: const Text('CHOOSE DESTINATION'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                '5-Day Forecast',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.plum.withOpacity(0.85),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: forecast.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final day = forecast[index];

                    return Container(
                      width: 70,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day['day'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.plum,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            day['icon'] as IconData,
                            color: AppColors.teal,
                            size: 22,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day['temp'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.plum.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
