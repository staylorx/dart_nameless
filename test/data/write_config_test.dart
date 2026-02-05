import 'dart:io';

import 'package:nameless/src/domain/repositories/config_repository.dart';
import 'package:test/test.dart';
import 'package:nameless/src/data/repositories/config_repository_impl.dart';

void main() {
  late ConfigRepository repo;
  setUpAll(() {
    repo = ConfigRepositoryImpl();
  });
  group('ConfigRepositoryImpl writeConfig', () {
    test('writes YAML file to given path', () async {
      final tempDir = await Directory.systemTemp.createTemp('cfg_write_test_');
      try {
        final file = File('${tempDir.path}${Platform.pathSeparator}out.yaml');

        final either = await repo.writeConfig(configPath: file.path).run();

        either.match((l) => fail('Unexpected failure: $l'), (u) {
          expect(file.existsSync(), isTrue);
          final content = file.readAsStringSync();
          expect(content, contains('positionalThresholdPublic'));
          expect(content, contains('allowedPositionalNames'));
          expect(content, contains('- ref'));
        });
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
