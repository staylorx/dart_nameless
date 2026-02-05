import 'dart:io';
import 'package:nameless/nameless.dart';
import 'package:nameless/src/data/dtos/config_dto.dart';
import 'package:shouldly/shouldly.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

class MockFile extends Mock implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(File('dummy'));
  });

  group('Given a Config - yaml & file', () {
    group('When creating from YAML string', () {
      group('When YAML is valid', () {
        test('Then it parses correctly', () {
          const yaml = '''
positionalThresholdPublic: 2
allowedPositionalNames:
  - custom
excludeGlobs:
  - '*.dart'
''';

          final config = ConfigDto.fromYamlString(yaml);

          config.positionalThresholdPublic.should.be(2);
          config.allowedPositionalNames.should.be(['custom']);
          config.excludeGlobs.should.be(['*.dart']);
        });
      });

      group('When YAML is invalid', () {
        test('Then it throws YamlException', () {
          const invalidYaml = '''
positionalThresholdPublic: 2
invalid: yaml: syntax
''';

          expect(
            () => ConfigDto.fromYamlString(invalidYaml),
            throwsA(isA<YamlException>()),
          );
        });
      });

      group('When YAML is empty', () {
        test('Then it uses defaults', () {
          const yaml = '';

          final config = ConfigDto.fromYamlString(yaml);

          Should.satisfyAllConditions([
            () => config.positionalThresholdPublic.should.be(1),
            () => config.allowedPositionalNames.should.be(['ref', 'message']),
            () => config.excludeGlobs.should.beEmpty(),
          ]);
        });
      });
    });

    group('When creating from file', () {
      late MockFile mockFile;

      setUp(() {
        mockFile = MockFile();
      });

      group('When file exists', () {
        test('Then it reads and parses the file', () {
          const yaml = '''
positionalThresholdPublic: 3
allowedPositionalNames:
  - fileParam
''';
          when(() => mockFile.existsSync()).thenReturn(true);
          when(() => mockFile.readAsStringSync()).thenReturn(yaml);

          final config = ConfigDto.fromFile(mockFile);

          Should.satisfyAllConditions([
            () => config.positionalThresholdPublic.should.be(3),
            () => config.allowedPositionalNames.should.be(['fileParam']),
            () => config.excludeGlobs.should.beEmpty(),
          ]);
        });
      });

      group('When file does not exist', () {
        test('Then it returns default config', () {
          when(() => mockFile.existsSync()).thenReturn(false);

          final config = ConfigDto.fromFile(mockFile);

          Should.satisfyAllConditions([
            () => config.positionalThresholdPublic.should.be(1),
            () => config.allowedPositionalNames.should.be(['ref', 'message']),
            () => config.excludeGlobs.should.beEmpty(),
          ]);
        });
      });
    });

    group('Integration tests', () {
      test('Then loading from actual YAML file works end-to-end', () async {
        final tempDir = await Directory.systemTemp.createTemp('config_test_');
        final file = File(
          '${tempDir.path}${Platform.pathSeparator}config.yaml',
        );
        await file.writeAsString('''
positionalThresholdPublic: 5
allowedPositionalNames:
  - integration
excludeGlobs:
  - '*.test'
''');

        final config = ConfigDto.fromFile(file);

        Should.satisfyAllConditions([
          () => config.positionalThresholdPublic.should.be(5),
          () => config.allowedPositionalNames.should.be(['integration']),
          () => config.excludeGlobs.should.be(['*.test']),
        ]);

        await tempDir.delete(recursive: true);
      });
    });

    group('Functional tests', () {
      test('Then user can load custom config from YAML string', () {
        const userYaml = '''
positionalThresholdPublic: 0
allowedPositionalNames:
  - name
  - value
excludeGlobs:
  - '**/build/**'
  - '**/node_modules/**'
''';

        final config = ConfigDto.fromYamlString(userYaml);

        Should.satisfyAllConditions([
          () => config.positionalThresholdPublic.should.be(0),
          () => config.allowedPositionalNames.should.containAll([
            'name',
            'value',
          ]),
          () => config.excludeGlobs.should.containAll([
            '**/build/**',
            '**/node_modules/**',
          ]),
        ]);
      });

      test('Then user can override defaults with map', () {
        final userMap = {
          'positionalThresholdPublic': 10,
          'allowedPositionalNames': ['arg'],
        };

        final config = Config.fromMap(userMap);

        Should.satisfyAllConditions([
          () => config.positionalThresholdPublic.should.be(10),
          () => config.allowedPositionalNames.should.be(['arg']),
          () => config.excludeGlobs.should.beEmpty(),
        ]);
      });
    });
  });
}
