import 'dart:convert';
import 'dart:io';

final dbFile = File(
  '${Platform.environment['HOME'] ?? Platform.environment['USERPROFILE']}/.fpm_db.json',
);

Map<String, dynamic>? _dbCache;

Future<Map<String, dynamic>> loadDB() async {
  if (_dbCache != null) return _dbCache!;
  if (!await dbFile.exists()) {
    await dbFile.writeAsString('{}');
    _dbCache = {};
    return _dbCache!;
  }
  final raw = jsonDecode(await dbFile.readAsString());

  final db = <String, dynamic>{};
  raw.forEach((key, value) {
    if (value is String) {
      db[key] = {'path': value, 'last_scanned': '', 'last_opened': ''};
    } else {
      db[key] = value;
    }
  });

  _dbCache = db;
  return _dbCache!;
}

Future<void> saveDB([Map<String, dynamic>? newDb]) async {
  final db = newDb ?? _dbCache ?? {};
  await dbFile.writeAsString(JsonEncoder.withIndent('  ').convert(db));
  _dbCache = db;
}
