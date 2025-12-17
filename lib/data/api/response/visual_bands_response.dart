import 'package:radiozeit/data/api/http_api.dart';
import 'package:radiozeit/data/api/response/server_response.dart';
import 'package:radiozeit/data/model/visual_chunk.dart';

class VisualBandsResponse extends ServerResponse {

  List<VisualChunk> chunks = [];


  VisualBandsResponse(super.response);

  @override
  parse(HttpApiResponse response) {
    super.parse(response);
    if(success) {
      if(response.data is List) {
        response.data.forEach((json) {
          chunks.add(VisualChunk.fromJson(json));
        });
      } else {
        success = false;
        message = "bands list not found";
      }
    }

  }
}