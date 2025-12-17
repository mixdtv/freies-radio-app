import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/json_map.dart';

class RadioListResponse extends ServerResponse{
  List<AppRadio> radioList = [];

  RadioListResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      JsonMap.toList(response.data).forEach((item) {
        radioList.add(AppRadio.fromJson(item));
      });
    }
  }

}