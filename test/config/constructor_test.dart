import 'dart:io';
import 'package:nameless/nameless.dart';
import 'package:shouldly/shouldly.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockFile extends Mock implements File {}

void main() {
  late Config config;
  setUpAll(() {
    registerFallbackValue(File('dummy'));
    config = const Config();
  });

  group('Given a Config - constructor', () {
    group('When constructing with default parameters', () {
      test('Then it creates instance with default values', () {
        Should.satisfyAllConditions([
          () => config.positionalThresholdPublic.should.be(1),
          () => config.allowedPositionalNames.should.be(['ref', 'message']),
          () => config.excludeGlobs.should.beEmpty(),
        ]);
      });
    });

    group('When constructing with custom parameters', () {
      test('Then it uses provided values', () {
        final config = Config(
          positionalThresholdPublic: 2,
          allowedPositionalNames: ['custom'],
          excludeGlobs: ['*.dart'],
        );

        Should.satisfyAllConditions([
          () => config.positionalThresholdPublic.should.be(2),
          () => config.allowedPositionalNames.should.be(['custom']),
          () => config.excludeGlobs.should.be(['*.dart']),
        ]);
      });
    });

    group('When copying with modifications', () {
      test('Then copyWith with no changes returns equivalent instance', () {
        final config = Config();
        final copy = Config(
          positionalThresholdPublic: config.positionalThresholdPublic,
          allowedPositionalNames: config.allowedPositionalNames,
          excludeGlobs: config.excludeGlobs,
        );

        Should.satisfyAllConditions([
          () => copy.positionalThresholdPublic.should.be(
            config.positionalThresholdPublic,
          ),
          () => copy.allowedPositionalNames.should.be(
            config.allowedPositionalNames,
          ),
          () => copy.excludeGlobs.should.be(config.excludeGlobs),
        ]);
      });

      test('Then constructor with modifications changes specified fields', () {
        final config = Config();
        final modified = Config(
          positionalThresholdPublic: 3,
          allowedPositionalNames: config.allowedPositionalNames,
          excludeGlobs: config.excludeGlobs,
        );

        Should.satisfyAllConditions([
          () => modified.positionalThresholdPublic.should.be(3),
          () => modified.allowedPositionalNames.should.be(
            config.allowedPositionalNames,
          ),
          () => modified.excludeGlobs.should.be(config.excludeGlobs),
        ]);
      });
    });
  });
}
