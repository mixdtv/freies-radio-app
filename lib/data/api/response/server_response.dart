import 'package:radiozeit/data/api/http_api.dart';

class ServerResponse {
  late bool success;
  late bool isCanceled;
  late int code;
  late String message;

  ServerResponse(HttpApiResponse response) {

    try {
      parse(response);
    } catch (e,s) {
      print(s);
      success = false;
      message = e.toString();
    }
  }

  parse(HttpApiResponse response) {
    code = response.code;
    success = (response.code == 200 || response.code == 201);
    isCanceled = response.isCanceled;
    message = response.errorMessage;
  }

  ServerResponse.custom({required this.success,required this.message});
}