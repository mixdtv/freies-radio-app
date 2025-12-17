import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:radiozeit/features/location/model/location.dart';

enum LocationPermissionStatus  { ALLOW,FORBIDDEN,DISABLED,FORBIDDEN_FOREVER}

final _log = Logger('LocationService');

class LocationService {

  static Future<Location?> getLocation() async {
    try {
      _log.info('getLocation: requesting current position');
      var pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );
      _log.info('getLocation: received position $pos');
      return Location(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (e) {
      _log.warning('getLocation: error $e');
      Position? position = await Geolocator.getLastKnownPosition();
      if(position != null) {
        _log.info('getLocation: using last known position $position');
        return Location(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
    }

    _log.warning('getLocation: returning null');
    return null;
  }

  static Future<bool> isHasPermission() async {
    var permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  static Future<bool> isForbiddenForever() async {
    var permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  static Future<bool> isLocationServiceEnabled() async {
    return  await Geolocator.isLocationServiceEnabled();
  }




  static Future<LocationPermissionStatus> requestLocationPermission() async {
    bool isEnabled = await isLocationServiceEnabled();
    if (!isEnabled) {
      return LocationPermissionStatus.DISABLED;//'Location services are disabled.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return LocationPermissionStatus.FORBIDDEN;//'Location permissions are denied';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return LocationPermissionStatus.FORBIDDEN_FOREVER;//'Location permissions are permanently denied, we cannot request permissions.';
    }

    return LocationPermissionStatus.ALLOW;
  }


}

