import 'package:flutter/material.dart';

class ProfileDescriptionField extends StatelessWidget {
  const ProfileDescriptionField({
    super.key,
    required this.controller,
    required this.validator,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String? Function(String?) validator;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.description_outlined,
              size: 20,
              color: scheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'О себе',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'опционально',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: fieldKey,
          controller: controller,
          minLines: 4,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            hintText: 'Пара слов о себе, привычках или любимых котиках',
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: scheme.primary.withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
