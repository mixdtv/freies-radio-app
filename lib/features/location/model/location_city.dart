import 'package:radiozeit/features/location/model/city.dart';
import 'package:radiozeit/features/location/model/location.dart';

class LocationCity {
  Location location;
  City city;

  LocationCity({
    required String city,
    required double lat,
    required double lng,
  }) : city = City(name: city),location = Location(latitude: lat, longitude: lng);


  @override
  String toString() {
    return "$city|$location";
  }

  static LocationCity? fromString(String? value) {

    if(value == null || value.isEmpty) return null;
    List<String> items = value.split("|");
    if(items.length != 3) return null;
    print("fromString $items");
    return LocationCity(
      city: items[0],
      lat: double.parse(items[1]),
      lng: double.parse(items[2]),
    );
  }
}