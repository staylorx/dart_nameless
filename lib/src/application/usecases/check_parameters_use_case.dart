import 'package:analyzer/dart/ast/ast.dart';
import '../../domain/entities/config.dart';

/// Result of checking function parameters
class ParameterCheckResult {
  final bool requiresNamedParameters;
  final int positionalCount;
  final List<String> parameterNames;

  const ParameterCheckResult({
    required this.requiresNamedParameters,
    required this.positionalCount,
    required this.parameterNames,
  });
}

/// Use case for checking if function parameters should use named parameters.
///
/// This encapsulates the core logic for determining whether a function, method,
/// or constructor has too many positional parameters and should use named
/// parameters instead.
class CheckParametersUseCase {
  /// Checks if the given parameters violate the configured thresholds.
  ///
  /// Returns a [ParameterCheckResult] with:
  /// - `requiresNamedParameters`: true if the parameters violate the rules
  /// - `positionalCount`: number of required positional parameters
  /// - `parameterNames`: list of parameter names extracted
  ParameterCheckResult call({
    required FormalParameterList? params,
    required bool isPublic,
    required Config config,
  }) {
    if (params == null) {
      return const ParameterCheckResult(
        requiresNamedParameters: false,
        positionalCount: 0,
        parameterNames: [],
      );
    }

    // Extract required positional parameters
    final src = params.toSource();
    final inside = src.substring(1, src.length - 1); // remove parens

    // Determine required positional part (before '[' or '{')
    final idxBrace = inside.indexOf('[');
    final idxCurly = inside.indexOf('{');
    int cut = inside.length;
    if (idxBrace >= 0) cut = idxBrace;
    if (idxCurly >= 0 && idxCurly < cut) cut = idxCurly;

    final requiredPart = inside.substring(0, cut).trim();
    if (requiredPart.isEmpty) {
      return const ParameterCheckResult(
        requiresNamedParameters: false,
        positionalCount: 0,
        parameterNames: [],
      );
    }

    final parts = requiredPart
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final positionalCount = parts.length;

    // Extract parameter names
    final paramNames = <String>[];
    for (final p in parts) {
      // Take last identifier-like token (the parameter name)
      final matches = RegExp(
        r"[A-Za-z_]\w*",
      ).allMatches(p).map((m) => m.group(0)!).toList();
      if (matches.isNotEmpty) paramNames.add(matches.last);
    }

    // Apply rules
    bool isProblem = false;
    final threshold = isPublic
        ? config.positionalThresholdPublic
        : config.positionalThresholdPrivate;

    if (positionalCount > threshold) {
      isProblem = true;
    }

    if (threshold == 1 && positionalCount == 1) {
      final name = paramNames.isNotEmpty ? paramNames.first : '';
      if (!config.allowedPositionalNames.contains(name)) {
        isProblem = true;
      }
    }

    return ParameterCheckResult(
      requiresNamedParameters: isProblem,
      positionalCount: positionalCount,
      parameterNames: paramNames,
    );
  }
}
