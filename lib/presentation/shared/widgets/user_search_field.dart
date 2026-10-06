import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/user.dart';

class UserSearchField extends StatelessWidget {
  final List<User> users;
  final String labelText;
  final IconData prefixIcon;
  final String? selectedId;
  final ValueChanged<User?> onSelected;
  final String? Function(User?)? validator;
  final bool enabled;
  final String? hint;

  const UserSearchField({
    super.key,
    required this.users,
    this.labelText = 'المستخدم',
    this.prefixIcon = Icons.person,
    this.selectedId,
    required this.onSelected,
    this.validator,
    this.enabled = true,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedId != null
        ? users.where((u) => u.id == selectedId).firstOrNull
        : null;

    return Autocomplete<User>(
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return users;
        return users.where((u) {
          return u.name.toLowerCase().contains(query) ||
              u.phone.contains(query);
        });
      },
      displayStringForOption: (user) => '${user.name} • ${user.phone}',
      initialValue: TextEditingValue(text: selected?.name ?? ''),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        if (selected != null && controller.text != selected.name) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (controller.text != selected.name) {
              controller.text = selected.name;
            }
          });
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hint ?? 'اكتب اسمًا للبحث...',
            prefixIcon: Icon(prefixIcon, size: 18),
            suffixIcon: selected != null
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onSelected(null);
                    },
                  )
                : null,
          ),
          validator: validator != null
              ? (value) => validator!(selected)
              : null,
          onFieldSubmitted: (_) => onSubmitted(),
        );
      },
      onSelected: (user) {
        onSelected(user);
      },
      optionsMaxHeight: 250,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topRight,
          child: SizedBox(
            width: 300,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              color: AppColors.surfaceCard,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final user = options.elementAt(index);
                    final isSelected = user.id == selectedId;
                    return InkWell(
                      key: ValueKey(user.id),
                      onTap: () => onSelected(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : null,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.surfaceLow,
                              child: Text(
                                user.name.characters.first,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    user.phone,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check,
                                  color: AppColors.primary, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
