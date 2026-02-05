import 'package:equatable/equatable.dart';

/// Configuration for the named parameters scanner.
///
/// Defines the rules for detecting unnamed positional parameters in Dart code.
class Config with EquatableMixin {
  /// The maximum number of positional parameters allowed before flagging as an issue for public methods.
  final int positionalThresholdPublic;

  /// The maximum number of positional parameters allowed before flagging as an issue for private methods.
  final int positionalThresholdPrivate;

  /// Names of parameters that are allowed to be positional even if they are the only parameter.
  final List<String> allowedPositionalNames;

  /// Glob patterns for files to exclude from scanning.
  final List<String> excludeGlobs;

  const Config({
    this.positionalThresholdPublic = 1,
    this.positionalThresholdPrivate = 0,
    this.allowedPositionalNames = const ['ref', 'message'],
    this.excludeGlobs = const [],
  });

  Config copyWith({
    int? positionalThresholdPublic,
    int? positionalThresholdPrivate,
    List<String>? allowedPositionalNames,
    List<String>? excludeGlobs,
  }) {
    return Config(
      positionalThresholdPublic:
          positionalThresholdPublic ?? this.positionalThresholdPublic,
      positionalThresholdPrivate:
          positionalThresholdPrivate ?? this.positionalThresholdPrivate,
      allowedPositionalNames:
          allowedPositionalNames ?? this.allowedPositionalNames,
      excludeGlobs: excludeGlobs ?? this.excludeGlobs,
    );
  }

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      positionalThresholdPublic: map['positionalThresholdPublic'] as int? ?? 1,
      positionalThresholdPrivate:
          map['positionalThresholdPrivate'] as int? ?? 0,
      allowedPositionalNames:
          (map['allowedPositionalNames'] as List<dynamic>?)?.cast<String>() ??
          ['ref', 'message'],
      excludeGlobs:
          (map['excludeGlobs'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'positionalThresholdPublic': positionalThresholdPublic,
    'positionalThresholdPrivate': positionalThresholdPrivate,
    'allowedPositionalNames': allowedPositionalNames,
    'excludeGlobs': excludeGlobs,
  };

  @override
  String toString() => toJson().toString();

  @override
  List<Object?> get props => [
    positionalThresholdPublic,
    positionalThresholdPrivate,
    allowedPositionalNames,
    excludeGlobs,
  ];
}
