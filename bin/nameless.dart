import 'dart:io';

import 'package:args/args.dart';
import 'package:nameless/src/data/repositories/config_repository_impl.dart';
import 'package:nameless/src/data/repositories/file_repository_impl.dart';
import 'package:nameless/src/application/usecases/scan_codebase_use_case.dart';
import 'commands/config.dart';

const String version = '1.0.0';

ArgParser buildParser() {
  final parser = ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addOption('config', abbr: 'c', help: 'Path to config YAML file')
    ..addOption(
      'format',
      abbr: 'f',
      help: 'Output format: text (default) | json',
      defaultsTo: 'text',
    )
    ..addOption('output', abbr: 'o', help: 'Output to file instead of stdout')
    ..addFlag('version', negatable: false, help: 'Print the tool version.');

  // Add config subcommand
  parser.addCommand('config', buildConfigParser());

  return parser;
}

void printUsage(ArgParser argParser) {
  stdout.writeln('Usage: nameless [options] [path]');
  stdout.writeln('       nameless config [options]');
  stdout.writeln('');
  stdout.writeln(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);

    if (results['help'] as bool) {
      printUsage(argParser);
      return;
    }
    if (results['version'] as bool) {
      stdout.writeln('nameless version: $version');
      return;
    }

    final configPath = results['config'] as String?;
    final command = results.command;
    if (command != null) {
      if (command.name == 'config') {
        await handleConfigCommand(command, argParser, configPath);
        return;
      }
    }

    // Main scan command
    final verbose = results['verbose'] as bool;
    final format = (results['format'] as String?) ?? 'text';
    final outputPath = results['output'] as String?;

    final path = results.rest.isNotEmpty
        ? results.rest.first
        : Directory.current.path;

    // Dependency injection
    final configRepo = ConfigRepositoryImpl();
    final fileRepo = FileRepositoryImpl();
    final useCase = ScanCodebaseUseCase(fileRepo);

    // Load config
    final configEither = await configRepo
        .loadConfig(configPath: configPath ?? '')
        .run();
    final config = configEither.match((failure) {
      stdout.writeln('Config error: $failure');
      exit(1);
    }, (cfg) => cfg);

    if (verbose) {
      stdout.writeln('[VERBOSE] Scanning path: $path');
      stdout.writeln(
        '[VERBOSE] Config: publicThreshold=${config.positionalThresholdPublic} privateThreshold=${config.positionalThresholdPrivate} allowed=${config.allowedPositionalNames} exclude=${config.excludeGlobs}',
      );
    }

    final findingsEither = await useCase
        .call(rootPath: path, config: config)
        .run();
    final findings = findingsEither.match((failure) {
      stdout.writeln('Scan error: $failure');
      exit(1);
    }, (f) => f);

    String output;
    if (format == 'json') {
      final list = findings
          .map(
            (f) => {
              'file': f.filePath,
              'line': f.line,
              'column': f.column,
              'declaration': f.declaration,
              'positional': f.positionalParamNames,
            },
          )
          .toList();
      output = list.toString();
    } else {
      if (findings.isEmpty) {
        output = 'No issues found.';
      } else {
        output = findings.map((f) => f.toString()).join('\n');
      }
    }

    if (outputPath != null) {
      await File(outputPath).writeAsString(output);
    } else {
      stdout.writeln(output);
    }
  } on FormatException catch (e) {
    stdout.writeln('Argument error: ${e.message}');
    stdout.writeln('');
    printUsage(argParser);
  }
}

// `config` subcommand handler moved to `bin/commands/config.dart`.
