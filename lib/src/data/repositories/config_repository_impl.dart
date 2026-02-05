import 'dart:io';
import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:yaml/yaml.dart';
import 'package:json2yaml/json2yaml.dart';

import '../dtos/config_dto.dart';
import '../../domain/entities/config.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/config_repository.dart';

class ConfigRepositoryImpl implements ConfigRepository {
  @override
  TaskEither<Failure, Config> loadConfig({String? configPath}) {
    return TaskEither.tryCatch(() async {
      if (configPath != null && configPath.isNotEmpty) {
        return _fromFile(File(configPath));
      } else {
        final defaultFile = File(
          '${Directory.current.path}${Platform.pathSeparator}.nameless.yaml',
        );
        if (defaultFile.existsSync()) {
          return _fromFile(defaultFile);
        } else {
          return const Config();
        }
      }
    }, (error, stack) => FileSystemFailure(error.toString()));
  }

  Config _fromFile(File file) {
    final content = file.readAsStringSync();
    final doc = loadYaml(content);
    final map = doc is YamlMap
        ? Map<String, dynamic>.from(doc)
        : <String, dynamic>{};
    final dto = ConfigDto.fromJson(map);
    return dto.toEntity();
  }

  @override
  TaskEither<Failure, Unit> writeConfig({String? configPath}) {
    return TaskEither.tryCatch(() async {
      final file = (configPath != null && configPath.isNotEmpty)
          ? File(configPath)
          : File(
              '${Directory.current.path}${Platform.pathSeparator}.nameless.yaml',
            );

      final dto = ConfigDto.fromEntity(const Config());
      final map = dto.toJson();
      final yaml = json2yaml(map);
      file.writeAsStringSync(yaml);
      return unit;
    }, (error, stack) => FileSystemFailure(error.toString()));
  }

  @override
  TaskEither<Failure, Config> loadFromJsonString({required String jsonString}) {
    return TaskEither.tryCatch(() async {
      final decoded = jsonDecode(jsonString);
      final map = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      final dto = ConfigDto.fromJson(map);
      return dto.toEntity();
    }, (error, stack) => ParseFailure(error.toString()));
  }

  @override
  TaskEither<Failure, Config> loadFromYamlString({required String yamlString}) {
    return TaskEither.tryCatch(() async {
      final cfg = ConfigDto.fromYamlString(yamlString);
      return cfg;
    }, (error, stack) => ParseFailure(error.toString()));
  }
}
