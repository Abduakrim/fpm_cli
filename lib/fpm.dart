#!/usr/bin/env dart

import 'scanner.dart';

void printUsage() => print('''
FPM - Flutter Project Manager
Usage:
  fpm scan
  fpm add <path>
  fpm list
  fpm open <project>
  fpm remove <project>
  fpm recent
  fpm search <keyword>
''');

Future<void> scanCommand() async => await scan();

Future<void> addCommand(String path) async => await addProject(path);

Future<void> listCommand() async => await listProjects();

Future<void> openCommand(String name) async => await openProject(name);

Future<void> removeCommand(String name) async => await removeProject(name);

Future<void> recentCommand() async => await recentProjects();

Future<void> searchCommand(String keyword) async =>
    await searchProjects(keyword);
