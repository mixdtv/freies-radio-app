import 'dart:ui';

import 'package:intl/intl.dart';

extension Date on DateTime {

  String toFormat(String mask) {
    return DateFormat(mask).format(this);
  }

  DateTime toDate() {
    return DateTime(year,month,day);
  }
}

extension Str on String {
  String stripHtml() {
    return replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

extension CustomColor on Color {

  static Color? parseCss(String color) {
    if(color.contains("#") && color.length == 7) {
      return Color(int.parse(color.substring(1, 7), radix: 16) + 0xFF000000);
    }
    return null;

  }

}

extension ListUpdate<T> on List<T> {
  List<T> update(int pos, T t) {
    List<T> list = [];
    list.add(t);
    replaceRange(pos, pos + 1, list);
    return this;
  }

  List<T> combineWith(List<T> newList) {
    List<T> list = List.from(newList);
    forEach((e) {
      if(!newList.contains(e)) {
        list.add(e);
      }
    });

    return list;
  }

  int sum(int Function(T) get) {
    int sum = 0;
    forEach((element) => sum += get(element));
    return sum;
  }

  T? tryGet(int i) {
    if (isEmpty ||  i >= length) return null;
    return this[i];
  }

  T? firstOrNullWhere(bool Function(T) compare) {
    if (isEmpty) return null;
    for (int i = 0; i < length; i++) {
      if (compare(this[i])) {
        return this[i];
      }
    }
    return null;
  }
}
