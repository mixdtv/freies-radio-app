import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/radio_program.dart';
import 'package:radiozeit/utils/json_map.dart';

class EpgResponseResponse extends ServerResponse {
  List<RadioEpg> list = [];
  EpgResponseResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      var data = JsonMap.toMap(response.data);
      if(data["msg"] is List) {
        data["msg"].forEach((e) {
          list.add(RadioEpg.fromJson(e));
        });
      } else {
        success = false;
        message = "Epg list not find";
      }
    }
  }

}