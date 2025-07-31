import 'dart:async';
import 'dart:io';

import 'package:fpm_cli/color_utils.dart';
import 'package:fpm_cli/db_manager.dart';

Future<bool> isFlutterProject(File pubspec) async {
  try {
    final content = await pubspec.readAsString();
    return content.contains(RegExp(r'^\s*flutter\s*:', multiLine: true));
  } catch (_) {
    return false;
  }
}

Future<List<String>> getDefaultScanPaths() async {
  final paths = <String>[];
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

  if (Platform.isWindows) {
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
    for (var l in letters) {
      final drive = '$l:/';
      if (Directory(drive).existsSync()) {
        paths.add(drive);
        final user = Platform.environment['USERNAME'] ?? '';
        paths.addAll([
          '$drive/Users/$user/Desktop',
          '$drive/Users/$user/Documents',
          '$drive/Users/$user/Downloads',
        ]);
      }
    }
  } else if (Platform.isMacOS) {
    paths.addAll([
      '/Applications',
      '$home/Desktop',
      '$home/Documents',
      '$home/Downloads',
      '$home/Projects',
    ]);
  } else if (Platform.isLinux) {
    paths.addAll([
      '/usr/local/',
      '/opt/',
      // ignore: unnecessary_string_interpolations
      '$home',
      '$home/Desktop',
      '$home/Documents',
    ]);
  }
  return paths;
}

Future<void> scan() async {
  final db = await loadDB();
  final paths = await getDefaultScanPaths();

  print('🔍 Scanning for Flutter projects...'.blue);

  final loadingChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
  var i = 0;

  Timer? spinner = Timer.periodic(Duration(milliseconds: 100), (_) {
    stdout.write('\r${loadingChars[i++ % loadingChars.length]} Scanning...');
  });

  for (var basePath in paths) {
    final dir = Directory(basePath);
    if (!dir.existsSync()) continue;

    List<FileSystemEntity> list;
    try {
      list = await dir.list(recursive: true, followLinks: false).toList();
    } catch (_) {
      continue;
    }

    await Future.wait(
      list.whereType<File>().map((file) async {
        if (!file.path.endsWith('pubspec.yaml')) return;

        final projectPath = file.parent.path;
        final projectName = projectPath.split(Platform.pathSeparator).last;
        final existing =
            db[projectName] is Map
                ? db[projectName] as Map<String, dynamic>
                : null;

        if (existing != null &&
            existing['last_scanned'] is String &&
            existing['last_scanned'].toString().isNotEmpty &&
            DateTime.tryParse(existing['last_scanned']) != null &&
            DateTime.now()
                    .difference(DateTime.parse(existing['last_scanned']))
                    .inHours <
                24) {
          return;
        }

        if (await isFlutterProject(file)) {
          db[projectName] = {
            'path': projectPath,
            'last_scanned': DateTime.now().toIso8601String(),
            'last_opened': existing?['last_opened'] ?? '',
          };
          stdout.write('\r');
          print('🟢 Found: $projectName → $projectPath'.green);
        }
      }),
    );
  }

  spinner.cancel();
  stdout.write('\r');
  print('✅ Scanning completed.'.blue);
  await saveDB(db);
}

Future<void> addProject(String path) async {
  final db = await loadDB();
  final dir = Directory(path);
  if (!await dir.exists()) return print('🔴 Folder not found'.red);

  final name = dir.path.split(Platform.pathSeparator).last;
  if (db[name]?['path'] == path) {
    print('🔵 Already exists: $name'.blue);
    return;
  }

  db[name] = {
    'path': dir.path,
    'last_scanned': DateTime.now().toIso8601String(),
    'last_opened': '',
  };
  await saveDB(db);
  print('🟢 Project added: $name'.green);
}

Future<void> listProjects() async {
  final db = await loadDB();
  if (db.isEmpty) return print('📂 No saved projects.'.blue);

  print('📂 Saved projects:'.blue);
  db.forEach((name, data) {
    print(' - $name → ${data['path']}'.green);
  });
}

Future<void> openProject(String name) async {
  final db = await loadDB();
  final project = db[name];
  if (project == null) return print('🔴 Project not found: $name'.red);

  final path = project['path'];
  final cmd = 'code';

  try {
    await Process.start(cmd, [path], runInShell: true);
    db[name]['last_opened'] = DateTime.now().toIso8601String();
    await saveDB(db);
    print('🟢 Opened in VS Code: $name'.green);
  } catch (e) {
    print('🔴 Error launching VS Code: $e'.red);
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

Future<void> recentProjects() async {
  final db = await loadDB();
  final recents =
      db.entries
          .where((e) => (e.value['last_opened'] as String).isNotEmpty)
          .toList()
        ..sort(
          (a, b) => DateTime.parse(
            b.value['last_opened'],
          ).compareTo(DateTime.parse(a.value['last_opened'])),
        );
  if (recents.isEmpty) return print('📂 No recent projects.'.blue);
  print('📂 Recently opened:'.blue);
  for (var e in recents.take(10)) {
    print(' - ${e.key} → ${e.value['last_opened']}');
  }
}

Future<void> searchProjects(String keyword) async {
  final db = await loadDB();
  final results =
      db.entries
          .where((e) => e.key.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
  if (results.isEmpty) return print('🔴 No projects found.'.red);
  print('📂 Search results:'.blue);
  for (var e in results) {
    print(' - ${e.key} → ${e.value['path']}');
  }
}
