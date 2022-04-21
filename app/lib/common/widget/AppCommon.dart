import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

Widget navBarTitle(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
  );
}

String getNameFromId(String name) {
  int start = 0, end = 0;
  if (name.contains('@')) {
    start = name.indexOf('@') + 1;
  }
  if (name.contains(':')) {
    end = name.indexOf(':');
  }
  return name.substring(start, end);
}

String formatedTime(int value) {
  int h, m;

  value = value % (24 * 3600);
  h = (value ~/ 3600);
  value %= 3600;
  m = value ~/ 60;

  // s = value - (h * 3600) - (m * 60);

  String result = '$h:$m';

  return result;
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}
