import 'package:equatable/equatable.dart';

class Finding with EquatableMixin {
  final String filePath;
  final int line;
  final int column;
  final String declaration;
  final List<String> positionalParamNames;

  const Finding({
    required this.filePath,
    required this.line,
    required this.column,
    required this.declaration,
    required this.positionalParamNames,
  });

  Finding copyWith({
    String? filePath,
    int? line,
    int? column,
    String? declaration,
    List<String>? positionalParamNames,
  }) {
    return Finding(
      filePath: filePath ?? this.filePath,
      line: line ?? this.line,
      column: column ?? this.column,
      declaration: declaration ?? this.declaration,
      positionalParamNames: positionalParamNames ?? this.positionalParamNames,
    );
  }

  @override
  String toString() =>
      '$filePath:$line:$column — $declaration — positional: ${positionalParamNames.join(", ")}';

  @override
  List<Object?> get props => [
    filePath,
    line,
    column,
    declaration,
    positionalParamNames,
  ];
}
