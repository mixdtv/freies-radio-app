import 'package:radiozeit/utils/extensions.dart';
import 'package:radiozeit/utils/json_map.dart';

class TranslateLang {
  String code;
  String title;



  factory TranslateLang.fromJson(dynamic json) {
    List<String> langList = JsonMap.toList(json).cast<String>();
    return TranslateLang(
      code: langList.tryGet(0) ?? "",
      title: langList.tryGet(1)?.capitalize() ?? "",
    );
  }

  TranslateLang({
    required this.code,
    required this.title,
  });

  @override
  String toString() {
    return '${code}_$title';
  }
}