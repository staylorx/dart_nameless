import 'package:fpdart/fpdart.dart';

import '../entities/config.dart';
import '../failures/failure.dart';

abstract class ConfigRepository {
  TaskEither<Failure, Config> loadConfig({required String configPath});
  TaskEither<Failure, Unit> writeConfig({required String configPath});
}
