import 'package:logging/logging.dart';
import 'package:radiozeit/features/location/model/location.dart';

// F-Droid build stub for LocationService.
//
// F-Droid rejects Google Play Services in published APKs. The `geolocator`
// package (used in the Play/iOS build) depends on `play-services-location`,
// which pulls GMS classes (auth, common, dynamite, location) into the binary.
// For the F-Droid build, this file is copied over `location_service.dart`
// during the F-Droid prebuild step, so no geolocator-using code is compiled.
//
// **Public API must stay in sync with location_service.dart.** If you add a
// method to the real LocationService, mirror it here as a no-op so the F-Droid
// build keeps compiling.
//
// Behaviour: returns `null` / `DISABLED` everywhere. The app's existing
// "location unavailable" UI path takes over and users select a city manually.

enum LocationPermissionStatus { ALLOW, FORBIDDEN, DISABLED, FORBIDDEN_FOREVER }

final _log = Logger('LocationService');

class LocationService {
  static Future<Location?> getLocation() async {
    _log.info('fdroid stub getLocation: location services not built in');
    return null;
  }

  static Future<bool> isHasPermission() async => false;

  static Future<bool> isForbiddenForever() async => false;

  static Future<bool> isLocationServiceEnabled() async => false;

  static Future<LocationPermissionStatus> requestLocationPermission() async =>
      LocationPermissionStatus.DISABLED;

  static Future<void> openLocationSettings() async {
    // No-op on F-Droid: the location permission isn't declared in this
    // build's manifest, so there's nothing useful to send the user to.
  }
}
