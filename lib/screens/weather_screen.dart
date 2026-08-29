import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../widgets/weather_card.dart';
import '../services/location_service.dart';
import '../services/weather_service.dart';
import '../models/weather_data.dart';
import 'location_picker_screen.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherData? _currentWeather;
  List<ForecastDay> _forecast = [];

  bool _loadingWeather = true;
  bool _loadingForecast = true;

  @override
  void initState() {
    super.initState();
    _loadInitialWeather();
  }

  // ----------------------------------------------------------
  // LOAD WEATHER ON SCREEN OPEN (uses GPS by default)
  // ----------------------------------------------------------

  Future<void> _loadInitialWeather() async {
    try {
      final position = await LocationService.getCurrentLocation();

      await _fetchAndSetWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingWeather = false;
        _loadingForecast = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  // ----------------------------------------------------------
  // FETCH CURRENT + FORECAST TOGETHER
  // ----------------------------------------------------------

  Future<void> _fetchAndSetWeather({
    required double latitude,
    required double longitude,
  }) async {
    setState(() {
      _loadingWeather = true;
      _loadingForecast = true;
    });

    try {
      final weather = await WeatherService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _currentWeather = weather;
        _loadingWeather = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingWeather = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    try {
      final forecast = await WeatherService.getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _forecast = forecast;
        _loadingForecast = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingForecast = false;
      });
    }
  }

  // ----------------------------------------------------------
  // GET USER'S CURRENT WEATHER (button)
  // ----------------------------------------------------------

  Future<void> _getWeather() async {
    try {
      final position = await LocationService.getCurrentLocation();

      await _fetchAndSetWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
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

    await _fetchAndSetWeather(latitude: latitude, longitude: longitude);
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

              WeatherCard(data: _currentWeather, isLoading: _loadingWeather),

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
                child: _loadingForecast
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.teal),
                      )
                    : _forecast.isEmpty
                    ? Center(
                        child: Text(
                          'Forecast unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.plum.withOpacity(0.5),
                          ),
                        ),
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _forecast.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final day = _forecast[index];

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
                                  day.weekdayLabel,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.plum,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Icon(day.icon, color: AppColors.teal, size: 22),
                                const SizedBox(height: 8),
                                Text(
                                  '${day.maxTempC.toStringAsFixed(0)}°',
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
