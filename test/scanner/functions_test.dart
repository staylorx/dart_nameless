import 'dart:io';
import 'package:shouldly/shouldly.dart';

import 'package:nameless/src/domain/repositories/file_repository.dart';
import 'package:test/test.dart';
import 'package:nameless/nameless.dart';

void main() {
  late FileRepository fileRepository;
  late ScanCodebaseUseCase scanDirectory;
  group('Given a Dart file scanner - functions', () {
    late Directory tempDir;
    late File testFile;
    late Config config;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('np_scanner_test_');
      testFile = File('${tempDir.path}${Platform.pathSeparator}test.dart');
      config = Config(
        positionalThresholdPublic: 1,
        allowedPositionalNames: ['ref', 'message'],
      );
      fileRepository = FileRepositoryImpl();
      scanDirectory = ScanCodebaseUseCase(fileRepository);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('When scanning function declarations', () {
      test(
        'Then detects functions with 2 positional parameters exceeding threshold',
        () async {
          await testFile.writeAsString('void foo(int a, int b) {}');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['a', 'b']);
          findings.first.declaration.should.startWith('void foo');
        },
      );

      test('Then detects functions with 3 positional parameters', () async {
        await testFile.writeAsString('void foo(int a, int b, int c) {}');

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: config,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.length.should.be(1);
        findings.first.positionalParamNames.should.be(['a', 'b', 'c']);
      });

      test(
        'Then allows functions with 1 positional parameter that is allowed',
        () async {
          await testFile.writeAsString('void foo(String ref) {}');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.should.beEmpty();
        },
      );

      test(
        'Then allows functions with 1 positional parameter that is allowed (message)',
        () async {
          await testFile.writeAsString('void foo(String message) {}');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.should.beEmpty();
        },
      );

      test(
        'Then detects functions with 1 positional parameter that is not allowed',
        () async {
          await testFile.writeAsString('void foo(int value) {}');

          final taskEither = scanDirectory(
            rootPath: tempDir.path,
            config: config,
          );

          final either = await taskEither.run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          Should.satisfyAllConditions([
            () => findings.length.should.be(1),
            () => findings.first.positionalParamNames.should.be(['value']),
          ]);
        },
      );

      test('Then allows functions with 0 positional parameters', () async {
        await testFile.writeAsString('void foo() {}');

        final findings = await scanDirectory(
          rootPath: tempDir.path,
          config: config,
        ).run();

        findings
            .getOrElse((l) => throw Exception('Failure: $l'))
            .should
            .beEmpty();
      });

      test('Then allows functions with only named parameters', () async {
        await testFile.writeAsString('void foo({int? a, int? b}) {}');

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: config,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.should.beEmpty();
      });

      test(
        'Then allows functions with only optional positional parameters',
        () async {
          await testFile.writeAsString('void foo([int? a, int? b]) {}');

          final findings = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          findings
              .getOrElse((l) => throw Exception('Failure: $l'))
              .should
              .beEmpty();
        },
      );

      test(
        'Then detects functions with mixed required and optional positional',
        () async {
          await testFile.writeAsString('void foo(int a, int b, [int? c]) {}');

          final taskEither = scanDirectory(
            rootPath: tempDir.path,
            config: config,
          );

          final either = await taskEither.run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          Should.satisfyAllConditions([
            () => findings.length.should.be(1),
            () => findings.first.positionalParamNames.should.be(['a', 'b']),
          ]);
        },
      );

      test('Then detects functions with mixed positional and named', () async {
        await testFile.writeAsString('void foo(int a, int b, {int? c}) {}');

        final taskEither = scanDirectory(
          rootPath: tempDir.path,
          config: config,
        );

        final either = await taskEither.run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () => findings.first.positionalParamNames.should.be(['a', 'b']),
        ]);
      });

      test('Then handles complex parameter types', () async {
        await testFile.writeAsString(
          'void foo(List<String> items, Map<String, dynamic> config) {}',
        );

        final taskEither = scanDirectory(
          rootPath: tempDir.path,
          config: config,
        );

        final either = await taskEither.run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () => findings.first.positionalParamNames.should.not.beEmpty(),
        ]);
      });

      test('Then handles generic types', () async {
        await testFile.writeAsString('void foo<T>(T value, U other) {}');

        final taskEither = scanDirectory(
          rootPath: tempDir.path,
          config: config,
        );

        final either = await taskEither.run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        Should.satisfyAllConditions([
          () => findings.length.should.be(1),
          () =>
              findings.first.positionalParamNames.should.be(['value', 'other']),
        ]);
      });

      test(
        'Then detects private functions with any positional parameters',
        () async {
          await testFile.writeAsString('void _foo(int a) {}');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['a']);
          findings.first.declaration.should.startWith('void _foo');
        },
      );

      test(
        'Then detects private functions with single positional parameter even if allowed',
        () async {
          await testFile.writeAsString('void _foo(String ref) {}');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['ref']);
          findings.first.declaration.should.startWith('void _foo');
        },
      );

      test(
        'Then detects private functions with multiple positional parameters',
        () async {
          await testFile.writeAsString('void _foo(int a, int b, int c) {}');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          Should.satisfyAllConditions([
            () => findings.length.should.be(1),
            () =>
                findings.first.positionalParamNames.should.be(['a', 'b', 'c']),
          ]);
        },
      );
    });
  });
}
