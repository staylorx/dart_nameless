import 'dart:io';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';
import 'package:nameless/nameless.dart';

void main() {
  late FileRepository fileRepository;
  late ScanCodebaseUseCase scanDirectory;
  group('Given a Dart file scanner - constructors', () {
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

    group('When scanning constructor declarations', () {
      test(
        'Then detects constructors with too many positional parameters',
        () async {
          await testFile.writeAsString('''
class MyClass {
  MyClass(int a, int b);
}
''');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['a', 'b']);
          findings.first.declaration.should.contain('MyClass(');
        },
      );

      test(
        'Then allows constructors with single allowed positional parameter',
        () async {
          await testFile.writeAsString('''
class MyClass {
  MyClass(String ref);
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

          findings.should.beEmpty();
        },
      );

      test('Then detects factory constructors', () async {
        await testFile.writeAsString('''
class MyClass {
  factory MyClass(int a, int b) => MyClass._();
  MyClass._();
}
''');

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: config,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        expect(findings, hasLength(1));
        expect(findings.first.positionalParamNames, ['a', 'b']);
        expect(findings.first.declaration, contains('factory MyClass'));
      });

      test('Then handles const constructors', () async {
        await testFile.writeAsString('''
class MyClass {
  const MyClass(int a, int b);
}
''');

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: config,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        expect(findings, hasLength(1));
        expect(findings.first.positionalParamNames, ['a', 'b']);
      });

      test(
        'Then detects private class constructors with any positional parameters',
        () async {
          await testFile.writeAsString('''
class _MyClass {
  _MyClass(int a);
}
''');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['a']);
          findings.first.declaration.should.contain('_MyClass(');
        },
      );

      test(
        'Then detects private class constructors with single positional parameter even if allowed',
        () async {
          await testFile.writeAsString('''
class _MyClass {
  _MyClass(String ref);
}
''');

          final either = await scanDirectory(
            rootPath: tempDir.path,
            config: config,
          ).run();

          final findings = either.getOrElse(
            (l) => throw Exception('Failure: $l'),
          );

          findings.length.should.be(1);
          findings.first.positionalParamNames.should.be(['ref']);
          findings.first.declaration.should.contain('_MyClass(');
        },
      );

      test(
        'Then detects private class constructors with multiple positional parameters',
        () async {
          await testFile.writeAsString('''
class _MyClass {
  _MyClass(int a, int b, int c);
}
''');

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
