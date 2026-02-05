import 'dart:io';

import 'package:args/args.dart';
import 'package:nameless/src/data/repositories/config_repository_impl.dart';
import 'package:nameless/src/domain/entities/config.dart';

ArgParser buildConfigParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addOption(
      'threshold',
      abbr: 't',
      help: 'Set positional threshold (int)',
      defaultsTo: '1',
    )
    ..addMultiOption(
      'allowed-names',
      abbr: 'a',
      help: 'Allowed single positional names',
      defaultsTo: ['ref', 'message'],
      splitCommas: true,
    )
    ..addMultiOption(
      'exclude-globs',
      abbr: 'e',
      help: 'Exclude globs',
      splitCommas: true,
    )
    ..addOption(
      'format',
      abbr: 'f',
      help: 'Output format: text (default) | json',
      defaultsTo: 'text',
    )
    ..addOption('output', abbr: 'o', help: 'Output to file instead of stdout');
}

Future<void> handleConfigCommand(
  ArgResults command,
  ArgParser mainParser,
  String? configPath,
) async {
  if (command['help'] as bool) {
    stdout.writeln('Usage: nameless config [options]');
    stdout.writeln('');
    stdout.writeln(mainParser.commands['config']!.usage);
    return;
  }

  final format = command['format'] as String? ?? 'text';
  final outputPath = command['output'] as String?;

  Config config;
  if (configPath != null) {
    final configRepo = ConfigRepositoryImpl();
    final configEither = await configRepo
        .loadConfig(configPath: configPath)
        .run();
    config = configEither.match((failure) {
      stdout.writeln('Config error: $failure');
      exit(1);
    }, (cfg) => cfg);

    // Apply subcommand overrides only if the user explicitly passed them.
    // Use `wasParsed` to detect if an option was provided.
    if (command.wasParsed('threshold')) {
      final t = int.tryParse(command['threshold'] as String? ?? '');
      if (t != null) {
        config = config.copyWith(positionalThresholdPublic: t);
      }
    }

    if (command.wasParsed('allowed-names')) {
      final names = command['allowed-names'] as List<String>?;
      if (names != null && names.isNotEmpty) {
        config = config.copyWith(allowedPositionalNames: names);
      }
    }

    if (command.wasParsed('exclude-globs')) {
      final excludes = command['exclude-globs'] as List<String>?;
      if (excludes != null && excludes.isNotEmpty) {
        config = config.copyWith(
          excludeGlobs: [...config.excludeGlobs, ...excludes],
        );
      }
    }
  } else {
    final thresholdStr = command['threshold'] as String?;
    final allowedNames =
        command['allowed-names'] as List<String>? ?? <String>[];
    final excludeGlobs =
        command['exclude-globs'] as List<String>? ?? <String>[];

    final threshold = int.tryParse(thresholdStr ?? '1') ?? 1;

    config = Config(
      positionalThresholdPublic: threshold,
      positionalThresholdPrivate: 0,
      allowedPositionalNames: allowedNames,
      excludeGlobs: excludeGlobs,
    );
  }

  String output;
  if (format == 'json') {
    output = config.toJson().toString();
  } else {
    output = config.toString();
  }

  if (outputPath != null) {
    await File(outputPath).writeAsString(output);
  } else {
    stdout.writeln(output);
  }
}
