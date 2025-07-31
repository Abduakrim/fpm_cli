#!/usr/bin/env dart

import 'package:fpm_cli/color_utils.dart';

import 'scanner.dart';
void printUsage() => print('''
FPM - Flutter Project Manager
                                  .         .           
8 8888888888   8 888888888o      ,8.       ,8.          
8 8888         8 8888    `88.   ,888.     ,888.         
8 8888         8 8888     `88  .`8888.   .`8888.        
8 8888         8 8888     ,88 ,8.`8888. ,8.`8888.       
8 888888888888 8 8888.   ,88',8'8.`8888,8^8.`8888.      
8 8888         8 888888888P',8' `8.`8888' `8.`8888.     
8 8888         8 8888      ,8'   `8.`88'   `8.`8888.    
8 8888         8 8888     ,8'     `8.`'     `8.`8888.   
8 8888         8 8888    ,8'       `8        `8.`8888.  
8 8888         8 8888   ,8'         `         `8.`8888. 

Usage:
  fpm scan
  fpm add <path>
  fpm list
  fpm open <project>
  fpm remove <project>
  fpm recent
  fpm search <keyword>
'''.blue);

Future<void> scanCommand() async => await scan();

Future<void> addCommand(String path) async => await addProject(path);

Future<void> listCommand() async => await listProjects();

Future<void> openCommand(String name) async => await openProject(name);

Future<void> removeCommand(String name) async => await removeProject(name);

Future<void> recentCommand() async => await recentProjects();

Future<void> searchCommand(String keyword) async =>
    await searchProjects(keyword);
