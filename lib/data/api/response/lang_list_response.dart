import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/translate_lang.dart';
import 'package:radiozeit/utils/json_map.dart';

class LangListResponse extends ServerResponse {
  List<TranslateLang> langs = [];
  LangListResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      List<dynamic> listJson = JsonMap.toList(response.data);
      for (var value in listJson) {
        langs.add(TranslateLang.fromJson(value));
      }
    }
  }
}