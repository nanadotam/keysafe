import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String? city;
  final String? country;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
  });

  String get displayName {
    final parts = [city, country].whereType<String>().toList();
    return parts.isNotEmpty
        ? parts.join(', ')
        : '${latitude.toStringAsFixed(4)}°, ${longitude.toStringAsFixed(4)}°';
  }

  String get coordsLabel =>
      '${latitude.toStringAsFixed(4)}° N, ${longitude.toStringAsFixed(4)}° E';
}

class LocationService {
  static Future<LocationResult?> getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      String? city;
      String? country;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = place.locality?.isNotEmpty == true
              ? place.locality
              : place.subAdministrativeArea;
          country = place.country;
        }
      } catch (_) {}

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }
}
