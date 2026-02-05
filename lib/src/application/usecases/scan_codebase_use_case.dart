import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:fpdart/fpdart.dart';

import '../../domain/entities/config.dart';
import '../../domain/entities/finding.dart';
import '../../domain/failures/failure.dart';
import '../../domain/repositories/file_repository.dart';
import 'check_parameters_use_case.dart';

typedef IntPair = ({int item1, int item2});

class ScanCodebaseUseCase {
  final FileRepository fileRepository;
  final CheckParametersUseCase checkParametersUseCase;

  ScanCodebaseUseCase(
    this.fileRepository, {
    CheckParametersUseCase? checkParametersUseCase,
  }) : checkParametersUseCase =
           checkParametersUseCase ?? CheckParametersUseCase();

  TaskEither<Failure, List<Finding>> call({
    required String rootPath,
    required Config config,
  }) {
    return fileRepository.listDartFiles(rootPath, config.excludeGlobs).flatMap((
      filePaths,
    ) {
      final tasks = filePaths.map(
        (path) => _scanFile(path: path, config: config),
      );
      return TaskEither(() async {
        final eithers = await Future.wait(tasks.map((t) => t.run()));
        final lefts = eithers.whereType<Left<Failure, List<Finding>>>();
        if (lefts.isNotEmpty) return left(lefts.first.value);
        final rights = eithers.whereType<Right<Failure, List<Finding>>>().map(
          (r) => r.value,
        );
        return right(rights.expand((f) => f).toList());
      });
    });
  }

  TaskEither<Failure, List<Finding>> _scanFile({
    required String path,
    required Config config,
  }) {
    return fileRepository.readFile(path).flatMap((content) {
      try {
        final result = parseString(content: content, throwIfDiagnostics: false);
        final unit = result.unit;
        final findings = <Finding>[];
        final visitor = _DeclarationVisitor(
          filePath: path,
          content: content,
          config: config,
          findings: findings,
          checkParametersUseCase: checkParametersUseCase,
        );
        unit.accept(visitor);
        return TaskEither.right(findings);
      } catch (e) {
        return TaskEither.left(ParseFailure('Failed to parse $path: $e'));
      }
    });
  }
}

class _DeclarationVisitor extends GeneralizingAstVisitor<void> {
  final String filePath;
  final String content;
  final Config config;
  final List<Finding> findings;
  final CheckParametersUseCase checkParametersUseCase;

  _DeclarationVisitor({
    required this.filePath,
    required this.content,
    required this.config,
    required this.findings,
    required this.checkParametersUseCase,
  });

  void _checkFormalParameters({
    required FormalParameterList? params,
    required AstNode node,
    required bool isPublic,
  }) {
    final result = checkParametersUseCase(
      params: params,
      isPublic: isPublic,
      config: config,
    );

    if (result.requiresNamedParameters) {
      final offset = node.offset;
      final loc = _offsetToLineColumn(content: content, offset: offset);
      final decl = node.toSource().split('\n').first;
      findings.add(
        Finding(
          filePath: filePath,
          line: loc.item1,
          column: loc.item2,
          declaration: decl,
          positionalParamNames: result.parameterNames,
        ),
      );
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkFormalParameters(
      params: node.functionExpression.parameters,
      node: node,
      isPublic: !node.name.lexeme.startsWith('_'),
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkFormalParameters(
      params: node.parameters,
      node: node,
      isPublic: !node.name.lexeme.startsWith('_'),
    );
    super.visitMethodDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    AstNode? current = node.parent;
    ClassDeclaration? classDecl;
    while (current != null) {
      if (current is ClassDeclaration) {
        classDecl = current;
        break;
      }
      current = current.parent;
    }
    bool isPublic = true;
    if (classDecl != null) {
      final nameId = classDecl.name;
      isPublic = !nameId.lexeme.startsWith('_');
    }
    _checkFormalParameters(
      params: node.parameters,
      node: node,
      isPublic: isPublic,
    );
    super.visitConstructorDeclaration(node);
  }
}

/// Returns (line, column) 1-based
IntPair _offsetToLineColumn({required String content, required int offset}) {
  final before = content.substring(0, offset);
  final lines = before.split('\n');
  final line = lines.length;
  final column = lines.isNotEmpty ? lines.last.length + 1 : 1;
  final intPair = (item1: line, item2: column);
  return intPair;
}
