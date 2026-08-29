import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/weather_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  // ----------------------------------------------------------
  // GET WEATHER USING GPS COORDINATES
  // ----------------------------------------------------------

  static Future<WeatherData> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = dotenv.env['WEATHER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Weather API key is missing.');
    }

    final url = Uri.parse(
      '$_baseUrl/current.json'
      '?key=$apiKey'
      '&q=$latitude,$longitude'
      '&aqi=no',
    );

    return _fetchWeather(url);
  }

  // ----------------------------------------------------------
  // GET WEATHER USING A CITY / LOCATION NAME
  // ----------------------------------------------------------

  static Future<WeatherData> getCurrentWeatherByCity(String city) async {
    final apiKey = dotenv.env['WEATHER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Weather API key is missing.');
    }

    final url = Uri.parse(
      '$_baseUrl/current.json'
      '?key=$apiKey'
      '&q=${Uri.encodeComponent(city)}'
      '&aqi=no',
    );

    return _fetchWeather(url);
  }

  // ----------------------------------------------------------
  // GET 5-DAY FORECAST USING GPS COORDINATES
  // ----------------------------------------------------------

  static Future<List<ForecastDay>> getForecast({
    required double latitude,
    required double longitude,
    int days = 5,
  }) async {
    final apiKey = dotenv.env['WEATHER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Weather API key is missing.');
    }

    final url = Uri.parse(
      '$_baseUrl/forecast.json'
      '?key=$apiKey'
      '&q=$latitude,$longitude'
      '&days=$days'
      '&aqi=no'
      '&alerts=no',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Forecast request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final forecast = data['forecast'] as Map<String, dynamic>;

    final forecastDays = forecast['forecastday'] as List<dynamic>;

    return forecastDays.map((dayJson) {
      final day = dayJson as Map<String, dynamic>;

      final dayData = day['day'] as Map<String, dynamic>;

      final condition = dayData['condition'] as Map<String, dynamic>;

      return ForecastDay(
        date: day['date'] as String,
        maxTempC: (dayData['maxtemp_c'] as num).toDouble(),
        minTempC: (dayData['mintemp_c'] as num).toDouble(),
        condition: condition['text'] as String,
      );
    }).toList();
  }

  // ----------------------------------------------------------
  // SEARCH LOCATIONS
  // ----------------------------------------------------------

  static Future<List<Map<String, dynamic>>> searchLocations(
    String query,
  ) async {
    final apiKey = dotenv.env['WEATHER_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Weather API key is missing.');
    }

    if (query.trim().isEmpty) {
      return [];
    }

    final url = Uri.parse(
      '$_baseUrl/search.json'
      '?key=$apiKey'
      '&q=${Uri.encodeComponent(query.trim())}',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Location search failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      return [];
    }

    return data.whereType<Map<String, dynamic>>().toList();
  }

  // ----------------------------------------------------------
  // COMMON WEATHER RESPONSE HANDLER
  // ----------------------------------------------------------

  static Future<WeatherData> _fetchWeather(Uri url) async {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Weather API request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final location = data['location'] as Map<String, dynamic>;

    final current = data['current'] as Map<String, dynamic>;

    final condition = current['condition'] as Map<String, dynamic>;

    return WeatherData(
      city: location['name'] as String,
      temperature: (current['temp_c'] as num).toDouble(),
      feelsLike: (current['feelslike_c'] as num).toDouble(),
      condition: condition['text'] as String,
      humidity: (current['humidity'] as num).toInt(),
      windSpeed: (current['wind_kph'] as num).toDouble(),
      uvIndex: (current['uv'] as num).toInt(),
    );
  }
}

// ============================================================
// FORECAST DAY MODEL
// (kept here since it's small and only used by forecast calls)
// ============================================================

class ForecastDay {
  final String date;
  final double maxTempC;
  final double minTempC;
  final String condition;

  const ForecastDay({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.condition,
  });

  /// Short weekday label, e.g. "Mon", from a "yyyy-MM-dd" date string.
  String get weekdayLabel {
    try {
      final parsed = DateTime.parse(date);
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return labels[parsed.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  /// Maps the condition text to a simple icon, matching the
  /// look of the original hardcoded forecast row.
  IconData get icon {
    final lower = condition.toLowerCase();

    if (lower.contains('rain') || lower.contains('drizzle')) {
      return Icons.grain;
    }
    if (lower.contains('snow')) {
      return Icons.ac_unit_outlined;
    }
    if (lower.contains('cloud') || lower.contains('overcast')) {
      return Icons.wb_cloudy_outlined;
    }
    if (lower.contains('sun') || lower.contains('clear')) {
      return Icons.wb_sunny_outlined;
    }

    return Icons.cloud_outlined;
  }
}
