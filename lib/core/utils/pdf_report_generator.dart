import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../domain/entities/report.dart';

const _gymName = 'Gym Pro';

class PdfReportGenerator {
  static pw.Font? _arabicFont;

  static Future<pw.Font> _loadFont() async {
    if (_arabicFont != null) return _arabicFont!;
    final data = await rootBundle.load('assets/fonts/Cairo.ttf');
    _arabicFont = pw.Font.ttf(data);
    return _arabicFont!;
  }

  static Future<Uint8List> generate(Report report, Map<String, dynamic> data) async {
    final font = await _loadFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => _buildContent(report, data, font),
      ),
    );

    return pdf.save();
  }

  static List<pw.Widget> _buildContent(
    Report report,
    Map<String, dynamic> data,
    pw.Font font,
  ) {
    final from = data['from'] as String? ?? '';
    final to = data['to'] as String? ?? '';
    final generatedAt = data['generated_at'] as String? ?? '';
    final generatedBy = data['generated_by_name'] as String? ?? report.generatedBy ?? 'غير معروف';

    final header = _buildHeader(report, from, to, generatedAt, generatedBy, font);

    switch (report.type) {
      case 'financial':
        return [header, ..._buildFinancial(data, font)];
      case 'attendance':
        return [header, ..._buildAttendance(data, font)];
      case 'operational':
        return [header, ..._buildOperational(data, font)];
      default:
        return [header];
    }
  }

  static pw.Widget _buildHeader(
    Report report,
    String from,
    String to,
    String generatedAt,
    String generatedBy,
    pw.Font font,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1A1D23'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            _gymName,
            style: pw.TextStyle(
              font: font,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FF5722'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            report.title,
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#FFFFFF'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '$from  -  $to',
            style: pw.TextStyle(
              font: font,
              fontSize: 11,
              color: PdfColor.fromHex('#9CA3AF'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Issued: $generatedAt  |  By: $generatedBy',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColor.fromHex('#9CA3AF'),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────── FINANCIAL ────────────────────
  static List<pw.Widget> _buildFinancial(Map<String, dynamic> data, pw.Font font) {
    final income = (data['income'] as num?)?.toDouble() ?? 0;
    final expense = (data['expense'] as num?)?.toDouble() ?? 0;
    final net = (data['net'] as num?)?.toDouble() ?? 0;
    final byCategory = Map<String, double>.from(
      (data['by_category'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
    );

    return [
      pw.Text('KPIs',
          style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _kpiCard('Income', '\$${income.toStringAsFixed(2)}', PdfColor.fromHex('#10B981'), font),
          _kpiCard('Expense', '\$${expense.toStringAsFixed(2)}', PdfColor.fromHex('#EF4444'), font),
          _kpiCard('Net', '\$${net.toStringAsFixed(2)}',
              net >= 0 ? PdfColor.fromHex('#10B981') : PdfColor.fromHex('#EF4444'), font),
        ],
      ),
      pw.SizedBox(height: 16),
      if (byCategory.isNotEmpty) ...[
        pw.Text('By Category',
            style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildTable(
          ['Category', 'Amount'],
          byCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)),
          (e) => [e.key, '\$${e.value.toStringAsFixed(2)}'],
          font,
        ),
      ],
    ];
  }

  // ──────────────────── ATTENDANCE ────────────────────
  static List<pw.Widget> _buildAttendance(Map<String, dynamic> data, pw.Font font) {
    final total = data['total_checkins'] as int? ?? 0;
    final unique = data['unique_trainees'] as int? ?? 0;
    final avg = data['avg_per_day'] as String? ?? '0';
    final daily = Map<String, int>.from(
      (data['daily'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ?? {},
    );

    final sortedDays = daily.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final maxDay = sortedDays.isNotEmpty
        ? sortedDays.reduce((a, b) => a.value > b.value ? a : b)
        : null;
    final minDay = sortedDays.isNotEmpty
        ? sortedDays.reduce((a, b) => a.value < b.value ? a : b)
        : null;

    return [
      pw.Text('KPIs',
          style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _kpiCard('Total Check-ins', '$total', PdfColor.fromHex('#3B82F6'), font),
          _kpiCard('Unique Trainees', '$unique', PdfColor.fromHex('#10B981'), font),
          _kpiCard('Avg/Day', avg, PdfColor.fromHex('#F59E0B'), font),
        ],
      ),
      pw.SizedBox(height: 16),
      if (sortedDays.isNotEmpty) ...[
        pw.Text('Daily Breakdown',
            style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _buildTable(
          ['Date', 'Check-ins'],
          sortedDays,
          (e) => [e.key, '${e.value}'],
          font,
          highlightRow: (row) {
            if (maxDay != null && row[0] == maxDay.key) return PdfColor.fromHex('#10B981');
            if (minDay != null && row[0] == minDay.key) return PdfColor.fromHex('#EF4444');
            return null;
          },
        ),
      ],
    ];
  }

  // ──────────────────── OPERATIONAL ────────────────────
  static List<pw.Widget> _buildOperational(Map<String, dynamic> data, pw.Font font) {
    final newMemberships = data['new_memberships'] as int? ?? 0;
    final expiringSoon = data['expiring_soon'] as int? ?? 0;
    final courseFillRate = data['course_fill_rate'] as String? ?? '0';
    final totalSessions = data['total_sessions'] as int? ?? 0;
    final hallOccupancy = Map<String, double>.from(
      (data['hall_occupancy'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
    );

    return [
      pw.Text('KPIs',
          style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _kpiCard('New Memberships', '$newMemberships', PdfColor.fromHex('#10B981'), font),
          _kpiCard('Expiring Soon', '$expiringSoon', PdfColor.fromHex('#F59E0B'), font),
          _kpiCard('Sessions', '$totalSessions', PdfColor.fromHex('#3B82F6'), font),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Center(
        child: pw.Text(
          'Course Fill Rate: $courseFillRate%',
          style: pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 16),
      if (hallOccupancy.isNotEmpty) ...[
        pw.Text('Hall Occupancy',
            style: pw.TextStyle(font: font, fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        ...hallOccupancy.entries.map((e) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(e.key,
                          style: pw.TextStyle(font: font, fontSize: 11)),
                      pw.Text('${e.value.toStringAsFixed(0)}%',
                          style: pw.TextStyle(font: font, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#2B303C'),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        width: 300 * (e.value / 100).clamp(0.0, 1.0),
                        decoration: pw.BoxDecoration(
                          color: _occupancyColor(e.value),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    ];
  }

  // ──────────────────── SHARED WIDGETS ────────────────────
  static pw.Widget _kpiCard(String label, String value, PdfColor color, pw.Font font) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1A1D23'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  font: font, fontSize: 18, fontWeight: pw.FontWeight.bold, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label,
              style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromHex('#9CA3AF')),
              textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(
    List<String> headers,
    List<dynamic> rows,
    List<String> Function(dynamic) rowBuilder,
    pw.Font font, {
    PdfColor? Function(List<String>)? highlightRow,
  }) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(font: font, fontSize: 10, fontWeight: pw.FontWeight.bold),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2B303C')),
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellHeight: 28,
      cellAlignment: pw.Alignment.centerRight,
      headerAlignment: pw.Alignment.centerRight,
      headers: headers,
      data: rows.map((r) {
        final cells = rowBuilder(r);
        return cells;
      }).toList(),
    );
  }

  static PdfColor _occupancyColor(double pct) {
    if (pct >= 80) return PdfColor.fromHex('#10B981');
    if (pct >= 50) return PdfColor.fromHex('#F59E0B');
    return PdfColor.fromHex('#EF4444');
  }
}
