import 'dart:io';
import 'package:shouldly/shouldly.dart';
import 'package:nameless/src/domain/repositories/file_repository.dart';
import 'package:test/test.dart';
import 'package:nameless/nameless.dart';

void main() {
  late ScanCodebaseUseCase scanDirectory;
  late FileRepository fileRepository;

  group('Given a Dart file scanner - thresholds and edgecases', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('np_scanner_test_');
      testFile = File('${tempDir.path}${Platform.pathSeparator}test.dart');
      fileRepository = FileRepositoryImpl();
      scanDirectory = ScanCodebaseUseCase(fileRepository);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('When using different configuration thresholds', () {
      test('Then threshold 0 detects all positional parameters', () async {
        await testFile.writeAsString('void foo(int a) {}');
        final strictConfig = Config(positionalThresholdPublic: 0);

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: strictConfig,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () => findings.first.positionalParamNames.should.be(['a']),
        ]);
      });

      test('Then threshold 2 allows up to 2 positional parameters', () async {
        await testFile.writeAsString('void foo(int a, int b) {}');
        final lenientConfig = Config(positionalThresholdPublic: 2);

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: lenientConfig,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });

      test('Then threshold 2 detects 3 positional parameters', () async {
        await testFile.writeAsString('void foo(int a, int b, int c) {}');
        final lenientConfig = Config(positionalThresholdPublic: 2);

        final taskEither = scanDirectory(
          rootPath: tempDir.path,
          config: lenientConfig,
        );

        final either = await taskEither.run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () => findings.first.positionalParamNames.should.be(['a', 'b', 'c']),
        ]);
      });
    });

    group('When handling edge cases', () {
      test('Then handles empty parameter lists', () async {
        await testFile.writeAsString('void foo() {}');

        final findings = await scanDirectory(
          rootPath: tempDir.path,
          config: Config(),
        ).run();

        findings
            .getOrElse((l) => throw Exception('Failure: $l'))
            .should
            .beEmpty();
      });

      test('Then handles function expressions', () async {
        await testFile.writeAsString('final func = (int a, int b) => null;');

        final findings = await scanDirectory(
          rootPath: tempDir.path,
          config: Config(),
        ).run();

        findings
            .getOrElse((l) => throw Exception('Failure: $l'))
            .should
            .beEmpty();
      });

      test('Then handles nested functions', () async {
        await testFile.writeAsString('''
void outer() {
  void inner(int a, int b) {}
}
''');

        final taskEither = scanDirectory(
          rootPath: tempDir.path,
          config: Config(),
        );

        final either = await taskEither.run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () => findings.first.positionalParamNames.should.be(['a', 'b']),
          () => findings.first.declaration.should.contain('void inner'),
        ]);
      });

      test('Then handles getter and setter methods', () async {
        await testFile.writeAsString('''
class MyClass {
  int get value => 0;
  set value(int v) {}
}
''');

        final taskEither = scanDirectory(
          rootPath: tempDir.path,
          config: Config(),
        );

        final either = await taskEither.run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () => findings.first.declaration.should.contain('set value'),
        ]);
      });
    });

    group('When excluding files', () {
      test('Then excludes files matching config excludeGlobs', () async {
        final excludedFile = File(
          '${tempDir.path}${Platform.pathSeparator}excluded.dart',
        );
        await excludedFile.writeAsString('void bad(int a, int b) {}');
        await File(
          '${tempDir.path}${Platform.pathSeparator}test.dart',
        ).writeAsString('void good(String ref) {}');

        final excludeConfig = Config(
          positionalThresholdPublic: 1,
          excludeGlobs: ['excluded.dart'],
        );

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: excludeConfig,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });

      test('Then excludes files matching .gitignore patterns', () async {
        final gitignore = File(
          '${tempDir.path}${Platform.pathSeparator}.gitignore',
        );
        await gitignore.writeAsString('ignored.dart\n');
        final ignoredFile = File(
          '${tempDir.path}${Platform.pathSeparator}ignored.dart',
        );
        await ignoredFile.writeAsString('void bad(int a, int b) {}');

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: Config(),
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });

      test(
        'Then threshold 1 allows single positional parameter if in allowed names',
        () async {
          await testFile.writeAsString('void foo(String ref) {}');
          final configWithAllowed = Config(
            positionalThresholdPublic: 1,
            allowedPositionalNames: ['ref'],
          );

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: configWithAllowed,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.should.beEmpty();
        },
      );

      test(
        'Then threshold 1 detects single positional parameter not in allowed names',
        () async {
          await testFile.writeAsString('void foo(String other) {}');
          final configWithAllowed = Config(
            positionalThresholdPublic: 1,
            allowedPositionalNames: ['ref'],
          );

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: configWithAllowed,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          Should.satisfyAllConditions([
            () => findings.length.should.be(1),
            () => findings.first.positionalParamNames.should.be(['other']),
          ]);
        },
      );

      test(
        'Then threshold 0 detects single positional parameter even if in allowed names',
        () async {
          await testFile.writeAsString('void foo(String ref) {}');
          final strictConfig = Config(
            positionalThresholdPublic: 0,
            allowedPositionalNames: ['ref'],
          );

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: strictConfig,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          Should.satisfyAllConditions([
            () => findings.length.should.be(1),
            () => findings.first.positionalParamNames.should.be(['ref']),
          ]);
        },
      );

      test(
        'Then threshold 2 allows single positional parameter regardless of allowed names',
        () async {
          await testFile.writeAsString('void foo(String other) {}');
          final lenientConfig = Config(
            positionalThresholdPublic: 2,
            allowedPositionalNames: ['ref'],
          );

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: lenientConfig,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.should.beEmpty();
        },
      );

      test('Then excludes files matching wildcard patterns', () async {
        final excludedFile1 = File(
          '${tempDir.path}${Platform.pathSeparator}test_excluded.dart',
        );
        await excludedFile1.writeAsString('void bad(int a, int b) {}');
        final excludedFile2 = File(
          '${tempDir.path}${Platform.pathSeparator}other_excluded.dart',
        );
        await excludedFile2.writeAsString('void bad(int a, int b) {}');
        await File(
          '${tempDir.path}${Platform.pathSeparator}test_good.dart',
        ).writeAsString('void good(String ref) {}');

        final excludeConfig = Config(
          positionalThresholdPublic: 1,
          excludeGlobs: ['*excluded*'],
        );

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: excludeConfig,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });

      test('Then excludes files in excluded directories', () async {
        final subDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}excluded_dir',
        );
        await subDir.create();
        final excludedFile = File(
          '${subDir.path}${Platform.pathSeparator}bad.dart',
        );
        await excludedFile.writeAsString('void bad(int a, int b) {}');
        await File(
          '${tempDir.path}${Platform.pathSeparator}good.dart',
        ).writeAsString('void good(String ref) {}');

        final excludeConfig = Config(
          positionalThresholdPublic: 1,
          excludeGlobs: ['excluded_dir/**'],
        );

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: excludeConfig,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });

      test('Then handles multiple exclude patterns', () async {
        final excludedFile1 = File(
          '${tempDir.path}${Platform.pathSeparator}file1.dart',
        );
        await excludedFile1.writeAsString('void bad(int a, int b) {}');
        final excludedFile2 = File(
          '${tempDir.path}${Platform.pathSeparator}file2.dart',
        );
        await excludedFile2.writeAsString('void bad(int a, int b) {}');
        await File(
          '${tempDir.path}${Platform.pathSeparator}allowed.dart',
        ).writeAsString('void good(String ref) {}');

        final excludeConfig = Config(
          positionalThresholdPublic: 1,
          excludeGlobs: ['file1.dart', 'file2.dart'],
        );

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: excludeConfig,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });
    });
  });
}
