import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/model/location_city.dart';
import 'package:radiozeit/utils/json_map.dart';

class CityListResponse extends ServerResponse{
  List<LocationCity> cityList = [
   // LocationCity(city: "Berlin", lat: 52.5170365, lng: 13.3888599)
  ];

  CityListResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      JsonMap.toList(response.data["suggestions"]).forEach((item) {
        cityList.add(LocationCity(
            city: JsonMap.toStr(item["city_name"]) ?? "Unknown",
            lat: JsonMap.toDouble(item["lat"]) ?? 0,
            lng: JsonMap.toDouble(item["lng"]) ?? 0,
        ));
      });
    }
  }
}