// Service pour exporter la liste de goals en CSV, Excel (XLSX) ou PDF et partager le fichier.

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/goal_model.dart';

class GoalExportService {
  static String _safeFileName(String base) => base.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  // Note: the `excel` package cell.value typing varies between versions.
  // We assign as dynamic to avoid strict CellValue typing issues across versions.

  static String _escapeCsv(String input) {
    // Double internal quotes and wrap in double quotes
    final escaped = input.replaceAll('"', '""');
    return '"$escaped"';
  }

  static Future<File> exportCsv(List<Goal> goals, {String? filename}) async {
    final now = DateTime.now();
    final df = DateFormat('yyyyMMdd_HHmmss');
    final name = filename ?? 'goals_${df.format(now)}.csv';

    final header = ['id', 'title', 'category', 'target', 'current', 'progress', 'deadline', 'createdAt', 'priority', 'description', 'emoji'];
    final lines = <String>[];
    lines.add(header.join(','));
    for (final g in goals) {
      final row = [
        _escapeCsv(g.id),
        _escapeCsv(g.title),
        _escapeCsv(g.category),
        g.target.toString(),
        g.current.toString(),
        g.progress.toStringAsFixed(2),
        _escapeCsv(g.deadline),
        _escapeCsv(g.createdAt.toIso8601String()),
        _escapeCsv(g.priority),
        _escapeCsv(g.description),
        _escapeCsv(g.emoji),
      ];
      lines.add(row.join(','));
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_safeFileName(name)}';
    final file = File(path);
    await file.writeAsString(lines.join('\n'), flush: true);
    return file;
  }

  static Future<File> exportExcel(List<Goal> goals, {String? filename}) async {
    final now = DateTime.now();
    final df = DateFormat('yyyyMMdd_HHmmss');
    final name = filename ?? 'goals_${df.format(now)}.xlsx';

    final ex = Excel.createExcel();
    final Sheet sheet = ex['Goals'];
    final header = ['id', 'title', 'category', 'target', 'current', 'progress', 'deadline', 'createdAt', 'priority', 'description', 'emoji'];

    // Write header row explicitly using CellIndex to satisfy typed API
    for (var c = 0; c < header.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0)).value = header[c] as dynamic;
    }

    // Write data rows
    var rowIndex = 1;
    for (final g in goals) {
      final values = [
        g.id,
        g.title,
        g.category,
        g.target,
        g.current,
        g.progress,
        g.deadline,
        g.createdAt.toIso8601String(),
        g.priority,
        g.description,
        g.emoji,
      ];
      for (var c = 0; c < values.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIndex)).value = values[c] as dynamic;
      }
      rowIndex++;
    }

    final bytes = ex.encode();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_safeFileName(name)}';
    final file = File(path);
    await file.writeAsBytes(bytes!);
    return file;
  }

  static Future<File> exportPdf(List<Goal> goals, {String? filename}) async {
    final now = DateTime.now();
    final df = DateFormat('yyyyMMdd_HHmmss');
    final name = filename ?? 'goals_${df.format(now)}.pdf';

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Header(level: 0, child: pw.Text('Goals Export')),
            pw.TableHelper.fromTextArray(
              headers: ['Title', 'Category', 'Target', 'Current', 'Progress', 'Deadline', 'Priority'],
              data: goals.map((g) => [g.title, g.category, g.target.toStringAsFixed(2), g.current.toStringAsFixed(2), '${g.progress.toStringAsFixed(1)}%', g.deadline, g.priority]).toList(),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${_safeFileName(name)}';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> shareFile(File file, {String? subject}) async {
    // Using top-level Share.shareXFiles for compatibility; this may be marked deprecated
    await Share.shareXFiles([XFile(file.path)], text: subject ?? 'Goals export');
  }
}
