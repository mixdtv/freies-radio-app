import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/radio.dart';
import 'package:radiozeit/utils/json_map.dart';

class RadioListResponse extends ServerResponse{
  List<AppRadio> radioList = [];

  /// The payload as it arrived, kept so it can be cached verbatim and parsed
  /// again on the next cold start. Caching this rather than re-serialising the
  /// models means the cache cannot drift from what the API actually sends.
  List<dynamic> raw = const [];

  RadioListResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      raw = JsonMap.toList(response.data);
      for (final item in raw) {
        radioList.add(AppRadio.fromJson(JsonMap.toMap(item)));
      }
    }
  }

}