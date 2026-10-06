import "package:flutter/material.dart";
class AppDropdown<T> extends StatelessWidget {
  final String label; final T? value; final List<DropdownMenuItem<T>> items; final void Function(T?)? onChanged;
  const AppDropdown({super.key, required this.label, this.value, required this.items, this.onChanged});
  @override Widget build(BuildContext context) => DropdownButtonFormField<T>(value: value, decoration: InputDecoration(labelText: label), items: items, onChanged: onChanged);
}
