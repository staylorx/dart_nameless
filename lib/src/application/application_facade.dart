import 'package:fpdart/fpdart.dart';
import 'package:nameless/nameless.dart';

/// A small application facade to help downstream users (CLI, integrations)
/// easily obtain the main usecases and sensible defaults.
class ApplicationFacade {
  final ScanCodebaseUseCase scanCodebaseUseCase;
  final ConfigRepository configRepository;
  final FileRepository fileRepository;

  ApplicationFacade({
    required this.scanCodebaseUseCase,
    required this.configRepository,
    required this.fileRepository,
  });

  /// Construct a facade wired with the package's default implementations.
  factory ApplicationFacade.withDefaults() {
    final fileRepo = FileRepositoryImpl();
    final configRepo = ConfigRepositoryImpl();
    final checkParamsUseCase = CheckParametersUseCase();
    final usecase = ScanCodebaseUseCase(
      fileRepo,
      checkParametersUseCase: checkParamsUseCase,
    );
    return ApplicationFacade(
      scanCodebaseUseCase: usecase,
      configRepository: configRepo,
      fileRepository: fileRepo,
    );
  }

  /// Convenience method that loads config (if needed) and runs a scan.
  TaskEither<Failure, List<Finding>> scan({
    required String rootPath,
    Config? config,
    String? configPath,
  }) {
    if (config != null) {
      return scanCodebaseUseCase.call(rootPath: rootPath, config: config);
    }

    return configRepository
        .loadConfig(configPath: configPath ?? '')
        .flatMap(
          (cfg) => scanCodebaseUseCase.call(rootPath: rootPath, config: cfg),
        );
  }
}
