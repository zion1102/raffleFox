import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'; // Import this for geocoding
import 'package:flutter/foundation.dart'; // Import this for debugPrint

class LocationService {
  static Future<String> getCountryCodeFromLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Return default country code for USA if permission is denied
        return 'TT'; // USA ISO code
      }

      // Get the user's current position
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Use the geocoding package to find the country code
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first.isoCountryCode ?? 'TT'; // Default to US if unavailable
      }
    } catch (e) {
      // Handle errors gracefully
      debugPrint('Error fetching location: $e');
      return 'TT'; // Default to US in case of error
    }
    return 'TT'; // Default to US if all else fails
  }
}
