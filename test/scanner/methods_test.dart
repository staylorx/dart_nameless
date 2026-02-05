import 'dart:io';
import 'package:shouldly/shouldly.dart';
import 'package:nameless/src/domain/repositories/file_repository.dart';
import 'package:test/test.dart';
import 'package:nameless/nameless.dart';

void main() {
  late FileRepository fileRepository;
  late ScanCodebaseUseCase scanDirectory;
  group('Given a Dart file scanner - methods', () {
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

    group('When scanning method declarations', () {
      test(
        'Then detects methods with too many positional parameters',
        () async {
          await testFile.writeAsString('''
class MyClass {
  void method(int a, int b) {}
}
''');

          final taskEither = scanDirectory(
            rootPath: tempDir.path,
            config: config,
          );

          final either = await taskEither.run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['a', 'b']);
          findings.first.declaration.should.contain('void method');
        },
      );

      test(
        'Then allows methods with single allowed positional parameter',
        () async {
          await testFile.writeAsString('''
class MyClass {
  void method(String ref) {}
}
''');

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

      test('Then detects static methods', () async {
        await testFile.writeAsString('''
class MyClass {
  static void method(int a, int b) {}
}
''');

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

      test('Then handles async methods', () async {
        await testFile.writeAsString('''
class MyClass {
  Future<void> method(int a, int b) async {}
}
''');

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

      test(
        'Then detects private methods with any positional parameters',
        () async {
          await testFile.writeAsString('''
class MyClass {
  void _method(int a) {}
}
''');

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
            () => findings.first.positionalParamNames.should.be(['a']),
            () => findings.first.declaration.should.contain('void _method'),
          ]);
        },
      );

      test(
        'Then detects private methods with single positional parameter even if allowed',
        () async {
          await testFile.writeAsString('''
class MyClass {
  void _method(String ref) {}
}
''');

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
            () => findings.first.positionalParamNames.should.be(['ref']),
          ]);
        },
      );

      test(
        'Then detects private methods with multiple positional parameters',
        () async {
          await testFile.writeAsString('''
class MyClass {
  void _method(int a, int b, int c) {}
}
''');

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
                findings.first.positionalParamNames.should.be(['a', 'b', 'c']),
          ]);
        },
      );
    });
  });
}
