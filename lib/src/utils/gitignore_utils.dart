import 'dart:io';

import 'package:glob/glob.dart';

List<String> loadGitIgnoreLines(Directory root) {
  final file = File('${root.path}${Platform.pathSeparator}.gitignore');
  if (!file.existsSync()) return [];
  try {
    return file
        .readAsLinesSync()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && !e.startsWith('#'))
        .toList();
  } catch (_) {
    return [];
  }
}

bool isExcluded(
  String path,
  List<String> excludeGlobs,
  List<String> gitignore,
) {
  final normalizedPath = path.replaceAll('\\', '/');
  for (final g in gitignore) {
    if (g.isEmpty) continue;
    final glob = Glob(g);
    if (glob.matches(normalizedPath)) return true;
  }
  for (final g in excludeGlobs) {
    if (g.isEmpty) continue;
    final glob = Glob(g);
    if (glob.matches(normalizedPath)) return true;
  }
  return false;
}
