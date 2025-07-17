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
  printInfo('''
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
  fpm remove <project>   Remove a project
''');
}

Future<bool> _isFlutterProject(File pubspec) async {
  try {
    final content = await pubspec.readAsString();
    return content.contains(RegExp(r'^\s*flutter\s*:', multiLine: true));
  } catch (_) {
    return false;
  }
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

  printInfo('🔍 Auto scanning folders:');
  for (var path in defaultPaths) {
    final dir = Directory(path);
    if (!dir.existsSync()) continue;

    printInfo('➡ Scanning: $path');
    try {
      await for (var entity in dir.list(recursive: true, followLinks: false)) {
        try {
          if (entity is File &&
              entity.path.endsWith('pubspec.yaml') &&
              await _isFlutterProject(entity)) {
            final name = entity.parent.path.split(Platform.pathSeparator).last;
            db[name] = entity.parent.path;
            printSucces('🟢 Project found: $name → ${entity.parent.path}');
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      continue;
    }
  }

  await saveDB(db);
  printInfo('📂 Scanning completed.');
}

Future<void> addProject(String path) async {
  final db = await loadDB();
  final dir = Directory(path);
  if (!await dir.exists()) {
    printError('🔴 Folder not found');
    return;
  }
  final name = dir.path.split(Platform.pathSeparator).last;
  db[name] = dir.path;
  await saveDB(db);
  printSucces('🟢 Project added: $name');
}

Future<void> listProjects() async {
  final db = await loadDB();
  if (db.isEmpty) {
    printInfo('No saved projects.');
    return;
  }
  printInfo('📂 Saved projects:');
  db.forEach((name, path) {
    if (!name.startsWith('__')) {
      printInfo(' - $name → $path');
    }
  });
}

Future<void> openProject(String name) async {
  final db = await loadDB();

  if (!db.containsKey(name)) {
    printError('🔴 Project "$name" not found in database');
    return;
  }

  final projectPath =
      Platform.isWindows ? db[name]!.replaceAll('/', '\\') : db[name]!;

  printInfo('🔍 Opening project: $name → $projectPath');

  try {
    final vscodePath = findVSCodePath();

    if (vscodePath != null) {
      await Process.start(vscodePath, [projectPath], runInShell: true);
      printSucces('🟢 Opened in VS Code: $name');
      return;
    }

    if (!Platform.isWindows) {
      await Process.start('code', [projectPath], runInShell: true);
      printSucces('🟢 Opened in VS Code (code from PATH)');
      return;
    }

    await Process.run('cmd', ['/c', 'start', '', 'code', projectPath]);
    printSucces('🟢 Opened in VS Code (cmd start)');
  } catch (e) {
    printError('🔴 Error while launching VS Code: $e');
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
    printSucces('🟢 Removed: $name');
  } else {
    printError('🔴 Project not found');
  }
}
