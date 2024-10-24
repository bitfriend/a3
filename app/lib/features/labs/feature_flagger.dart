import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::labs::feature_flag');

extension on Enum {
  String keyName() => name;
}

Features<T> featuresFromJson<T extends Enum>(
  List<dynamic> json,
  List<T> defaultOn,
  Function fromString,
) {
  return Features<T>(
    flags: featureFlagsFromJson(json, fromString),
    defaultOn: defaultOn,
  );
}

List<FeatureFlag<T>> featureFlagsFromJson<T extends Enum>(
  List<dynamic> json,
  Function fromString,
) {
  List<FeatureFlag<T>> flags = List.from(
    json.map((json) {
      final key = json['key']!;
      try {
        final feature = fromString(key).expect('enum parsing from key failed');
        final active = json['active'];
        return FeatureFlag<T>(feature: feature, active: active);
      } catch (e) {
        return null;
      }
    }).where((x) => x != null),
  );
  return flags;
}

class FeatureFlag<T extends Enum> {
  late T feature;
  late bool active;
  FeatureFlag({required this.feature, required this.active});

  Map toJson() {
    Map fromObject = {
      'key': feature.keyName(),
      'active': active,
    };
    return fromObject;
  }
}

@immutable
class Features<T extends Enum> {
  final List<FeatureFlag<T>> flags;
  final List<T> defaultOn;
  const Features({required this.flags, required this.defaultOn});

  String toJson() => json.encode(flags);

  bool isActive(T feat) {
    for (final flag in flags) {
      if (flag.feature == feat) {
        return flag.active;
      }
    }
    return defaultOn.contains(feat); // default on check
  }

  Features<T> updateFlag(T feat, bool active) {
    final List<FeatureFlag<T>> newFlags = List.from(flags);
    newFlags.removeWhere((flag) => flag.feature == feat);
    if (active || (defaultOn.contains(feat) && !active)) {
      newFlags.add(FeatureFlag(feature: feat, active: active));
    }
    _log.info('new active $newFlags, $defaultOn');
    return Features(flags: newFlags, defaultOn: defaultOn);
  }
}
