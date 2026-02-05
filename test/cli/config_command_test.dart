import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('Given a CLI `config` command', () {
    test('prints config loaded from YAML file', () async {
      final result = await Process.run('dart', [
        'run',
        'bin/nameless.dart',
        'config',
        '--config',
        'example/config.example.yaml',
      ]);

      expect(result.exitCode, 0);
      final out = result.stdout as String;
      expect(out, contains('positionalThresholdPublic'));
      expect(out, contains('allowedPositionalNames'));
      expect(out, contains('excludeGlobs'));
      expect(out, contains('ref'));
    });

    test('applies explicit threshold override when config provided', () async {
      final result = await Process.run('dart', [
        'run',
        'bin/nameless.dart',
        'config',
        '--config',
        'example/config.example.yaml',
        '--threshold',
        '5',
      ]);

      expect(result.exitCode, 0);
      final out = result.stdout as String;
      expect(out, contains('positionalThresholdPublic: 5'));
    });

    test('uses provided flags when no config path is given', () async {
      final result = await Process.run('dart', [
        'run',
        'bin/nameless.dart',
        'config',
        '--threshold',
        '2',
        '--allowed-names',
        'x,y',
        '--format',
        'json',
      ]);

      expect(result.exitCode, 0);
      final out = result.stdout as String;
      expect(out, contains('positionalThresholdPublic'));
      expect(out, contains('2'));
      expect(out, contains('x'));
      expect(out, contains('y'));
    });
  });
}
