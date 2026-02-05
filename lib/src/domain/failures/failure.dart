abstract class Failure {
  final String message;
  Failure(this.message);
}

class FileSystemFailure extends Failure {
  FileSystemFailure(super.message);

  @override
  String toString() => 'FileSystemFailure: $message';
}

class ParseFailure extends Failure {
  ParseFailure(super.message);

  @override
  String toString() => 'ParseFailure: $message';
}
