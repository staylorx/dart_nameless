import 'dart:io';

import 'package:yaml/yaml.dart';

import '../../domain/entities/config.dart';

class ConfigDto {
  final int positionalThresholdPublic;
  final int positionalThresholdPrivate;
  final List<String> allowedPositionalNames;
  final List<String> excludeGlobs;

  const ConfigDto({
    required this.positionalThresholdPublic,
    required this.positionalThresholdPrivate,
    required this.allowedPositionalNames,
    required this.excludeGlobs,
  });

  factory ConfigDto.fromJson(Map<String, dynamic> json) {
    return ConfigDto(
      positionalThresholdPublic: _parseInt(
        json['positionalThresholdPublic'],
        defaultValue: 1,
      ),
      positionalThresholdPrivate: _parseInt(
        json['positionalThresholdPrivate'],
        defaultValue: 0,
      ),
      allowedPositionalNames: json['allowedPositionalNames'] is List
          ? List<String>.from(json['allowedPositionalNames'] as List)
          : const ['ref', 'message'],
      excludeGlobs: json['excludeGlobs'] is List
          ? List<String>.from(json['excludeGlobs'] as List)
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'positionalThresholdPublic': positionalThresholdPublic,
      'positionalThresholdPrivate': positionalThresholdPrivate,
      'allowedPositionalNames': allowedPositionalNames,
      'excludeGlobs': excludeGlobs,
    };
  }

  Config toEntity() {
    return Config(
      positionalThresholdPublic: positionalThresholdPublic,
      positionalThresholdPrivate: positionalThresholdPrivate,
      allowedPositionalNames: allowedPositionalNames,
      excludeGlobs: excludeGlobs,
    );
  }

  factory ConfigDto.fromEntity(Config cfg) {
    return ConfigDto(
      positionalThresholdPublic: cfg.positionalThresholdPublic,
      positionalThresholdPrivate: cfg.positionalThresholdPrivate,
      allowedPositionalNames: cfg.allowedPositionalNames,
      excludeGlobs: cfg.excludeGlobs,
    );
  }

  static Config fromMap(Map<String, dynamic> map) {
    return Config(
      positionalThresholdPublic: _parseInt(
        map['positionalThresholdPublic'],
        defaultValue: 1,
      ),
      positionalThresholdPrivate: _parseInt(
        map['positionalThresholdPrivate'],
        defaultValue: 0,
      ),
      allowedPositionalNames: map['allowedPositionalNames'] is List
          ? List<String>.from(map['allowedPositionalNames'] as List)
          : const ['ref', 'message'],
      excludeGlobs: map['excludeGlobs'] is List
          ? List<String>.from(map['excludeGlobs'] as List)
          : const [],
    );
  }

  static Config fromYamlString(String yaml) {
    if (yaml.trim().isEmpty) return fromMap({});
    final doc = loadYaml(yaml);
    if (doc == null) return fromMap({});
    if (doc is! YamlMap && doc is! Map) {
      throw YamlException('Invalid YAML document', null);
    }
    final map = <String, dynamic>{};
    final ymap = doc as Map;
    for (final entry in ymap.keys) {
      final key = entry.toString();
      final value = ymap[entry];
      map[key] = value;
    }
    return fromMap(map);
  }

  static Config fromFile(File file) {
    if (!file.existsSync()) return fromMap({});
    final content = file.readAsStringSync();
    return fromYamlString(content);
  }

  static int _parseInt(dynamic v, {required int defaultValue}) {
    if (v is int) return v;
    if (v is String) {
      final parsed = int.tryParse(v);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }
}
