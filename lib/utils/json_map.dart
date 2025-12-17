import 'package:intl/intl.dart';

class JsonMap {
  static String? toStr(dynamic json) {
    if(json == null) return null;
    return json.toString();
  }

  static DateTime? toDate(dynamic json,String format) {
    if(json is String && json.isNotEmpty) {
      return DateFormat(format).parse(json);
    };
    return null;
  }
  static int? toInt(dynamic json) {
    if(json is int) return json;
    if(json is double) return json.toInt();
    if(json is String) return int.tryParse(json);
    return null;
  }

  static double? toDouble(dynamic json) {
    if(json is int) return json.toDouble();
    if(json is double) return json;
    if(json is String) return double.tryParse(json);
    return null;
  }

  static Map<String,dynamic> toMap(dynamic json) {
    if(json is Map<String,dynamic>) return json;
    return {};
  }

  static List<dynamic> toList(dynamic json) {
    if(json is List) return json;
    return [];
  }
}