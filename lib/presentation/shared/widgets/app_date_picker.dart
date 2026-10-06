import "package:flutter/material.dart";
class AppDatePicker extends StatelessWidget {
  final String label; final DateTime? selectedDate; final void Function(DateTime) onPicked;
  const AppDatePicker({super.key, required this.label, this.selectedDate, required this.onPicked});
  @override Widget build(BuildContext context) => InkWell(onTap: () async { final d = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) onPicked(d); }, child: InputDecorator(decoration: InputDecoration(labelText: label), child: Text(selectedDate?.toIso8601String().split("T").first ?? "???? ???????")));
}
