import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Gets the user's current GPS position.
  static Future<Position> getCurrentLocation() async {
    // Check whether location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location services are disabled. Please enable location services.',
      );
    }

    // Check the current permission.
    LocationPermission permission = await Geolocator.checkPermission();

    // Ask the user for permission if it has not been granted.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }
    }

    // The user permanently denied location permission.
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission was permanently denied. '
        'Please enable it from your device settings.',
      );
    }

    // Get the current GPS position.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
