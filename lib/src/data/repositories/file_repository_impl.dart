import 'dart:io';

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import '../../domain/repositories/file_repository.dart';
import '../../utils/gitignore_utils.dart';

class FileRepositoryImpl implements FileRepository {
  @override
  TaskEither<Failure, List<String>> listDartFiles(
    String rootPath,
    List<String> excludeGlobs,
  ) {
    return TaskEither.tryCatch(() async {
      final root = Directory(rootPath);
      if (!root.existsSync()) throw Exception('Directory not found: $rootPath');
      final gitignorePatterns = loadGitIgnoreLines(root);
      final files = <String>[];
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final relativePath = entity.path.replaceFirst(
            '${root.path}${Platform.pathSeparator}',
            '',
          );
          if (!isExcluded(relativePath, excludeGlobs, gitignorePatterns)) {
            files.add(entity.path);
          }
        }
      }
      return files;
    }, (error, stack) => FileSystemFailure(error.toString()));
  }

  @override
  TaskEither<Failure, String> readFile(String path) {
    return TaskEither.tryCatch(() async {
      final file = File(path);
      if (!file.existsSync()) throw Exception('File not found: $path');
      return file.readAsString();
    }, (error, stack) => FileSystemFailure(error.toString()));
  }
}
