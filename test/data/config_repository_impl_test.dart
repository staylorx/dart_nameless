import 'dart:io';

import 'package:nameless/src/domain/repositories/config_repository.dart';
import 'package:test/test.dart';
import 'package:nameless/src/data/repositories/config_repository_impl.dart';
import 'package:nameless/src/domain/entities/config.dart';
import 'package:nameless/src/domain/failures/failure.dart';

void main() {
  late ConfigRepository repo;
  setUpAll(() {
    repo = ConfigRepositoryImpl();
  });
  group('ConfigRepositoryImpl', () {
    test('loads config from provided file path', () async {
      final tempDir = await Directory.systemTemp.createTemp('cfg_repo_test_');
      try {
        final file = File('${tempDir.path}${Platform.pathSeparator}cfg.yaml');
        await file.writeAsString('''
positionalThresholdPublic: 3
allowedPositionalNames:
  - alpha
  - beta
excludeGlobs:
  - build/
''');

        final either = await repo.loadConfig(configPath: file.path).run();

        either.match((l) => fail('Unexpected failure: $l'), (cfg) {
          expect(cfg, isA<Config>());
          expect(cfg.positionalThresholdPublic, 3);
          expect(cfg.allowedPositionalNames, ['alpha', 'beta']);
          expect(cfg.excludeGlobs, ['build/']);
        });
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('loads config from JSON string', () async {
      final json = '''{
  "positionalThresholdPublic": 4,
  "allowedPositionalNames": ["one", "two"],
  "excludeGlobs": ["gen/"]
}''';

      final either = await repo.loadFromJsonString(jsonString: json).run();

      either.match((l) => fail('Unexpected failure: $l'), (cfg) {
        expect(cfg.positionalThresholdPublic, 4);
        expect(cfg.allowedPositionalNames, ['one', 'two']);
        expect(cfg.excludeGlobs, ['gen/']);
      });
    });

    test('returns ParseFailure for invalid JSON string', () async {
      final badJson = '{ not-a-json }';

      final either = await repo.loadFromJsonString(jsonString: badJson).run();

      either.match((l) {
        expect(l, isA<ParseFailure>());
      }, (cfg) => fail('Expected failure but got $cfg'));
    });

    test('loads config from YAML string', () async {
      final yaml = '''
positionalThresholdPublic: 5
allowedPositionalNames:
  - a
  - b
excludeGlobs:
  - out/
''';

      final either = await repo.loadFromYamlString(yamlString: yaml).run();

      either.match((l) => fail('Unexpected failure: $l'), (cfg) {
        expect(cfg.positionalThresholdPublic, 5);
        expect(cfg.allowedPositionalNames, ['a', 'b']);
        expect(cfg.excludeGlobs, ['out/']);
      });
    });

    test('empty YAML string yields defaults', () async {
      final either = await repo.loadFromYamlString(yamlString: '').run();

      either.match((l) => fail('Unexpected failure: $l'), (cfg) {
        expect(cfg.positionalThresholdPublic, 1);
        expect(cfg.allowedPositionalNames, ['ref', 'message']);
        expect(cfg.excludeGlobs, isEmpty);
      });
    });

    test(
      'falls back to .nameless.yaml in current directory when no path provided',
      () async {
        final tempDir = await Directory.systemTemp.createTemp('cfg_repo_cwd_');
        final oldCwd = Directory.current;
        try {
          Directory.current = tempDir;
          final file = File(
            '${tempDir.path}${Platform.pathSeparator}.nameless.yaml',
          );
          await file.writeAsString('''
positionalThresholdPublic: 2
allowedPositionalNames:
  - x
excludeGlobs:
  - .dart_tool/
''');

          final repo = ConfigRepositoryImpl();
          final either = await repo.loadConfig(configPath: null).run();

          either.match((l) => fail('Unexpected failure: $l'), (cfg) {
            expect(cfg.positionalThresholdPublic, 2);
            expect(cfg.allowedPositionalNames, ['x']);
            expect(cfg.excludeGlobs, ['.dart_tool/']);
          });
        } finally {
          Directory.current = oldCwd;
          await tempDir.delete(recursive: true);
        }
      },
    );

    test('uses defaults when YAML types are invalid', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'cfg_repo_invalid_',
      );
      try {
        final file = File('${tempDir.path}${Platform.pathSeparator}bad.yaml');
        await file.writeAsString('''
positionalThresholdPublic: 'not-an-int'
allowedPositionalNames: not-a-list
excludeGlobs: 123
''');

        final repo = ConfigRepositoryImpl();
        final either = await repo.loadConfig(configPath: file.path).run();

        either.match((l) => fail('Unexpected failure: $l'), (cfg) {
          // Repository treats invalid types as defaults
          expect(cfg.positionalThresholdPublic, 1);
          expect(cfg.allowedPositionalNames, ['ref', 'message']);
          expect(cfg.excludeGlobs, isEmpty);
        });
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
