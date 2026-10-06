import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AppTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  const AppTable({super.key, required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceLow),
          dataRowColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.hovered) ? AppColors.surfaceLow : AppColors.surfaceCard),
          columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)))).toList(),
          rows: rows.map((r) => DataRow(cells: r.map((w) => DataCell(w)).toList())).toList(),
        ),
      ),
    );
  }
}
