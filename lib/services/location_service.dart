import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  // Get current location with city and country name
  static Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'success': false,
          'message': 'Location services are disabled.',
        };
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'success': false,
            'message': 'Location permissions are denied',
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'success': false,
          'message': 'Location permissions are permanently denied.',
        };
      }

      // This is the key fix - add a small delay after permission is granted
      // to ensure location services are fully initialized
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Short delay to let location services initialize
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Safely get place details using geocoding
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          final locality = place.locality ??
              place.subLocality ??
              place.administrativeArea ??
              '';
          final country = place.country ?? '';

          return {
            'success': true,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'locality': locality,
            'country': country,
            'formatted_location': locality.isNotEmpty && country.isNotEmpty
                ? '$locality, $country'
                : (locality.isNotEmpty
                    ? locality
                    : (country.isNotEmpty ? country : 'Unknown location'))
          };
        }
      } catch (geocodeError) {
        // If geocoding fails, still return coordinates
        return {
          'success': true,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'formatted_location':
              'Location found (${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)})'
        };
      }

      return {
        'success': true,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'formatted_location': 'Location found'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get location: $e',
      };
    }
  }
}
