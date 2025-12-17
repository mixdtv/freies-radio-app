
import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/features/location/model/city.dart';
import 'package:radiozeit/utils/json_map.dart';

class CityResponse extends ServerResponse{
  City? city;

  CityResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      city = City(name: JsonMap.toStr(response.data["city_name"]) ?? "");
    }
  }

}