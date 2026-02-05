import 'package:nameless/src/data/dtos/config_dto.dart';
import 'package:shouldly/shouldly.dart';
import 'package:test/test.dart';

void main() {
  group('Given a Config - fromMap', () {
    group('When map has valid values', () {
      test('Then it creates config with map values', () {
        final map = {
          'positionalThresholdPublic': 4,
          'allowedPositionalNames': ['param1', 'param2'],
          'excludeGlobs': ['*.tmp', '*.bak'],
        };

        final config = ConfigDto.fromMap(map);

        config.positionalThresholdPublic.should.be(4);
        config.allowedPositionalNames.should.be(['param1', 'param2']);
        config.excludeGlobs.should.be(['*.tmp', '*.bak']);
      });
    });

    group('When map has invalid positionalThresholdPublic', () {
      test('Then it uses default value', () {
        final map = {'positionalThresholdPublic': 'invalid'};

        final config = ConfigDto.fromMap(map);

        config.positionalThresholdPublic.should.be(1);
      });

      test('Then it parses string number', () {
        final map = {'positionalThresholdPublic': '3'};

        final config = ConfigDto.fromMap(map);

        config.positionalThresholdPublic.should.be(3);
      });
    });

    group('When map has invalid allowedPositionalNames', () {
      test('Then it uses default value', () {
        final map = {'allowedPositionalNames': 'not a list'};

        final config = ConfigDto.fromMap(map);

        config.allowedPositionalNames.should.be(['ref', 'message']);
      });
    });

    group('When map has invalid excludeGlobs', () {
      test('Then it uses default value', () {
        final map = {'excludeGlobs': 123};

        final config = ConfigDto.fromMap(map);

        config.excludeGlobs.should.beEmpty();
      });
    });

    group('When map is empty', () {
      test('Then it uses all defaults', () {
        final config = ConfigDto.fromMap({});

        Should.satisfyAllConditions([
          () => config.positionalThresholdPublic.should.be(1),
          () => config.allowedPositionalNames.should.be(['ref', 'message']),
          () => config.excludeGlobs.should.beEmpty(),
        ]);
      });
    });
  });
}
