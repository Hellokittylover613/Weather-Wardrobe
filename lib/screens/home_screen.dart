import 'package:flutter/material.dart';

import '../models/wardrobe_item.dart';
import '../models/weather_data.dart';
import '../services/location_service.dart';
import '../services/wardrobe_service.dart';
import '../services/weather_service.dart';
import '../utils/app_colors.dart';
import '../widgets/wardrobe_item_card.dart';
import 'outfit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WardrobeService _wardrobeService = WardrobeService();

  WeatherData? _weather;
  List<WardrobeItem> _suggestedItems = [];

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  // ============================================================
  // MAP TEMPERATURE TO A WARDROBE WEATHER TAG
  // ============================================================

  String _bucketForWeather(WeatherData weather) {
    final condition = weather.condition.toLowerCase();

    if (condition.contains('rain') || condition.contains('drizzle')) {
      return 'Rainy';
    }

    final temp = weather.temperature;

    if (temp >= 30) return 'Hot';
    if (temp >= 20) return 'Warm';
    if (temp >= 10) return 'Cool';
    return 'Cold';
  }

  // ============================================================
  // LOAD WEATHER + MATCHING WARDROBE ITEMS
  // ============================================================

  Future<void> _loadSuggestions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();

      final weather = await WeatherService.getCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final rawItems = await _wardrobeService.getWardrobeItems();

      final items = rawItems
          .map((e) => WardrobeItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      final bucket = _bucketForWeather(weather);

      final matching = items
          .where((item) => item.weather == bucket || item.weather == 'Any')
          .toList();

      if (!mounted) return;

      setState(() {
        _weather = weather;
        _suggestedItems = matching;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weather Wardrobe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.plum,
                ),
              ),

              const SizedBox(height: 6),

              if (_weather != null)
                Text(
                  '${_weather!.city} • ${_weather!.temperature.toStringAsFixed(0)}°C • ${_weather!.condition}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.plum.withOpacity(0.65),
                  ),
                ),

              const SizedBox(height: 18),

              const Text(
                "Today's Outfit Suggestions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.plum,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Based on your wardrobe and current weather',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.plum.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 44,
                                color: AppColors.plum.withOpacity(0.35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.plum.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadSuggestions,
                                child: const Text('Try again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _suggestedItems.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.checkroom_outlined,
                                size: 50,
                                color: AppColors.plum.withOpacity(0.35),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _weather != null
                                    ? 'No wardrobe items tagged for ${_bucketForWeather(_weather!)} weather yet.'
                                    : 'No wardrobe items found.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.plum.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        itemCount: _suggestedItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: .68,
                            ),
                        itemBuilder: (context, index) {
                          final item = _suggestedItems[index];

                          return WardrobeItemCard(
                            item: item,
                            onDelete: () {},
                            onEdit: () {},
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OutfitScreen(),
                      ),
                    );
                  },
                  child: const Text('View All Outfits'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
