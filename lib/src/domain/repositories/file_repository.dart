import 'package:fpdart/fpdart.dart';

import '../failures/failure.dart';

abstract class FileRepository {
  TaskEither<Failure, List<String>> listDartFiles(
    String rootPath,
    List<String> excludeGlobs,
  );
  TaskEither<Failure, String> readFile(String path);
}
