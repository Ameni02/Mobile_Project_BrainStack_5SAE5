// Liste les goals présents dans la base `goals.db`.
// Usage: dart run tools/list_goals.dart

import 'dart:async';
import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = await databaseFactory.getDatabasesPath();
  final path = p.join(dbPath, 'finance_dashboard.db');
  print('DB path = $path');

  final db = await databaseFactory.openDatabase(path);
  final rows = await db.query('goals', orderBy: 'createdAt DESC');
  if (rows.isEmpty) {
    print('Aucun goal trouvé.');
  } else {
    print('Found ${rows.length} goals:\n');
    for (final r in rows) {
      final data = json.decode(r['data'] as String) as Map<String, dynamic>;
      print('- id: ${r['id']}');
      print('  title: ${r['title']}');
      print('  category: ${r['category']}');
      print('  target: ${r['target']}  current: ${r['current']}');
      print('  deadline: ${r['deadline']}');
      print('  data JSON keys: ${data.keys.join(', ')}\n');
    }
  }

  await db.close();
}
