import 'dart:io';

Future<void> main() async {
  final hookFile = File('.git/hooks/pre-commit');

  await hookFile.parent.create(recursive: true);

  await hookFile.writeAsString('''
#!/bin/sh
exec dart run dart_pre_commit
''');

  if (!Platform.isWindows) {
    await Process.run('chmod', ['+x', hookFile.path]);
  }

  print('Git pre-commit hook installed at ${hookFile.path}');
}
