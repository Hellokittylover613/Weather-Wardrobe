class WeatherData {
  final String city;
  final double temperature;
  final double feelsLike;
  final String condition;
  final int humidity;
  final double windSpeed;
  final int uvIndex;

  const WeatherData({
    required this.city,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
  });
}
