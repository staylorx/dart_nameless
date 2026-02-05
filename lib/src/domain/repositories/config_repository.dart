import 'package:fpdart/fpdart.dart';

import '../entities/config.dart';
import '../failures/failure.dart';

abstract class ConfigRepository {
  TaskEither<Failure, Config> loadConfig({required String configPath});
  TaskEither<Failure, Unit> writeConfig({required String configPath});

  // Load config from raw JSON string
  TaskEither<Failure, Config> loadFromJsonString({required String jsonString});

  // Load config from raw YAML string
  TaskEither<Failure, Config> loadFromYamlString({required String yamlString});
}
