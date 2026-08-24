import 'dart:convert';

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
