#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';

import 'package:fpm_cli/color_utils.dart';

final String dbPath =
    '${Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']}/.fpm_db.json';

Future<Map<String, String>> loadDB() async {
  final file = File(dbPath);
  if (!await file.exists()) {
    await file.writeAsString(jsonEncode({}));
    return {};
  }
  return Map<String, String>.from(jsonDecode(await file.readAsString()));
}

Future<void> saveDB(Map<String, String> db) async {
  final file = File(dbPath);
  await file.writeAsString(jsonEncode(db));
}

void printUsage() {
  print(
    '''
  ______   _____    __  __ 
 |  ____| |  __ \\  |  \\/  |
 | |__    | |__) | | \\  / |
 |  __|   |  ___/  | |\\/| |
 | |      | |      | |  | |
 |_|      |_|      |_|  |_|
                           
                           
FPM - Flutter Project Manager
Usage:
  fpm scan               Auto search for Flutter projects in standard folders
  fpm add <path>         Add a project manually
  fpm list               List all projects
  fpm open <project>     Open a project in VS Code
  fpm remove <project>   Remove a project from list
'''.blue,
  );
}

Future<bool> _isFlutterProject(File pubspec) async {
  try {
    final content = await pubspec.readAsString();
    return content.contains(RegExp(r'^\s*flutter\s*:', multiLine: true));
  } catch (_) {
    return false;
  }
}

void _printProgress(int current, int total) {
  final percent = (current / total * 100).toStringAsFixed(1);
  final barLength = 30;
  final filled = ((current / total) * barLength).round();
  final bar = '='.green * filled + '-' * (barLength - filled);
  stdout.write('\r[$bar] $percent% ($current/$total)');
}

Future<void> scan() async {
  final db = await loadDB();
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  final List<String> defaultPaths = [
    '$home/Desktop',
    '$home/Documents',
    '$home/Downloads',
    if (Platform.isWindows) 'C:/Program Files',
    if (Platform.isWindows) 'C:/Program Files (x86)',
    if (Platform.isMacOS) '/Applications',
  ];

  print('🔍 Auto scanning folders:'.blue);
  for (var path in defaultPaths) {
    final dir = Directory(path);

    if (!dir.existsSync()) continue;

    try {
      final allFiles =
          await dir
              .list(recursive: true, followLinks: false)
              .where((entity) => entity is File)
              .toList();

      var total = allFiles.length;
      var processed = 0;
      for (var entity in allFiles) {
        processed++;
        _printProgress(processed, total);
        try {
          if (entity is File &&
              entity.path.endsWith('pubspec.yaml') &&
              await _isFlutterProject(entity)) {
            final name = entity.parent.path.split(Platform.pathSeparator).last;
            db[name] = entity.parent.path;
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      continue;
    }
  }
  stdout.writeln('\r');
  for (var element in db.entries) {
    print('🟢 ${element.key}:${element.value}'.green);
  }
  await saveDB(db);
  print('📂 Scanning completed.'.blue);
}

Future<void> addProject(String path) async {
  final db = await loadDB();
  final dir = Directory(path);
  if (!await dir.exists()) {
    print('🔴 Folder not found'.green);
    return;
  }
  final name = dir.path.split(Platform.pathSeparator).last;
  db[name] = dir.path;
  await saveDB(db);
  print('🟢 Project added: $name'.green);
}

Future<void> listProjects() async {
  final db = await loadDB();
  if (db.isEmpty) {
    print('No saved projects.'.blue);
    return;
  }
  print('📂 Saved projects:'.blue);
  db.forEach((name, path) {
    if (!name.startsWith('__')) {
      print(' - $name → $path'.blue);
    }
  });
}

Future<void> openProject(String name) async {
  final db = await loadDB();

  if (!db.containsKey(name)) {
    print('🔴 Project "$name" not found in database'.red);
    return;
  }

  final projectPath =
      Platform.isWindows ? db[name]!.replaceAll('/', '\\') : db[name]!;

  print('🔍 Opening project: $name → $projectPath'.blue);

  try {
    final vscodePath = findVSCodePath();

    if (vscodePath != null) {
      await Process.start(vscodePath, [projectPath], runInShell: true);
      print('🟢 Opened in VS Code: $name'.green);
      return;
    }

    if (!Platform.isWindows) {
      await Process.start('code', [projectPath], runInShell: true);
      print('🟢 Opened in VS Code (code from PATH)'.green);
      return;
    }

    await Process.run('cmd', ['/c', 'start', '', 'code', projectPath]);
    print('🟢 Opened in VS Code (cmd start)'.green);
  } catch (e) {
    print('🔴 Error while launching VS Code: $e'.red);
  }
}

String? findVSCodePath() {
  if (Platform.isWindows) {
    final user = Platform.environment['USERNAME'] ?? '';
    final possiblePaths = [
      'C:/Users/$user/AppData/Local/Programs/Microsoft VS Code/Code.exe',
      'C:/Program Files/Microsoft VS Code/Code.exe',
      'C:/Program Files (x86)/Microsoft VS Code/Code.exe',
    ];
    for (var path in possiblePaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  } else if (Platform.isMacOS) {
    final path =
        '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code';
    return File(path).existsSync() ? path : null;
  } else {
    return 'code';
  }
}

Future<void> removeProject(String name) async {
  final db = await loadDB();
  if (db.remove(name) != null) {
    await saveDB(db);
    print('🟢 Removed: $name'.green);
  } else {
    print('🔴 Project not found'.red);
  }
}
