// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/sections/comment_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';
import 'section_container.dart';

class CommentSection extends StatelessWidget {
  final TextEditingController controller;
  final int maxLines;
  final String hintText;

  const CommentSection({
    super.key,
    required this.controller,
    this.maxLines = 5,
    this.hintText = 'Bemerkung eingeben...',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return SectionContainer(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border),
          ),
          child: TextFormField(
            textInputAction: TextInputAction.done,
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: theme.textPrimary),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.all(12),
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }
}