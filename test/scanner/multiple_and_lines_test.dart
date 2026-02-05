import 'dart:io';
import 'package:shouldly/shouldly.dart';
import 'package:nameless/src/domain/repositories/file_repository.dart';
import 'package:test/test.dart';
import 'package:nameless/nameless.dart';

void main() {
  late FileRepository fileRepository;
  late ScanCodebaseUseCase scanDirectory;
  group('Given a Dart file scanner - multiple declarations', () {
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

    group('When scanning multiple declarations', () {
      test('Then detects all problematic declarations', () async {
        await testFile.writeAsString('''
void func1(int a, int b) {}
void func2(String ref) {}
void func3(int x, int y, int z) {}

class MyClass {
  void method(int p, int q) {}
  MyClass(String message) {}
  MyClass.bad(int bad1, int bad2) {}
}
''');

        final either = await scanDirectory(
          rootPath: tempDir.path,
          config: config,
        ).run();

        final findings = either.getOrElse(
          (l) => throw Exception('Failure: $l'),
        );

        findings.length.should.be(4);

        final declarations = findings.map((f) => f.declaration).toList();
        Should.satisfyAllConditions([
          () =>
              declarations.any((d) => d.contains('void func1')).should.beTrue(),
          () =>
              declarations.any((d) => d.contains('void func3')).should.beTrue(),
          () => declarations
              .any((d) => d.contains('void method'))
              .should
              .beTrue(),
          () => declarations
              .any((d) => d.contains('MyClass.bad'))
              .should
              .beTrue(),
        ]);
      });

      test('Then correctly identifies line and column', () async {
        await testFile.writeAsString('''
void good(String ref) {}

void bad(int a, int b) {}
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
          () => findings.first.line.should.be(3),
          () => findings.first.column.should.beGreaterThan(0),
        ]);
      });
    });
  });
}
