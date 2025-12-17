import 'dart:math';

class Location {
  double latitude;
  double longitude;

  Location({
    required this.latitude,
    required this.longitude,
  });

  bool isChange(Location? location) {
    if(location == null) return true;
    double distance = calculateDistance(location);
    // You can define a threshold to determine if the location has changed significantly
    double threshold = 5.0; // 5 kilometers
    return distance > threshold;
  }

  double calculateDistance(Location location) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((location.latitude - latitude) * p)/2 +
        c(latitude * p) * c(location.latitude * p) *
            (1 - c((location.longitude - longitude) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  @override
  String toString() {
    return "$latitude|$longitude";
  }

  static Location? fromString(String value) {
    if(value.isEmpty) return null;
    var parts = value.split("|");
    return Location(
      latitude: double.parse(parts[0]),
      longitude: double.parse(parts[1]),
    );
  }
}