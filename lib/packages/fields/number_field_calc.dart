// lib/shared/fields/number_field_calc.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/services/icon_helper.dart';
import '../../core/theme/theme_provider.dart';


class NumberFieldCalc extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String iconName;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool isRequired;
  final bool isInvalid;
  final bool allowDecimals;

  const NumberFieldCalc({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    required this.iconName,
    this.onChanged,
    this.onTap,
    this.isRequired = false,
    this.isInvalid = false,
    this.allowDecimals = false,
  });

  bool get _isIOS {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInvalid ? theme.error : theme.border,
          width: isInvalid ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(theme),
          _buildTextField(theme),
        ],
      ),
    );
  }

  Widget _buildLabel(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          getAdaptiveIcon(
            iconName: iconName,
            defaultIcon: icon,
            size: 16,
            color: theme.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(ThemeProvider theme) {
    return TextFormField(
      controller: controller,
      keyboardType: _isIOS
          ? const TextInputType.numberWithOptions(signed: true, decimal: true)
          : TextInputType.number,
      onChanged: onChanged,
      onTap: onTap,
      readOnly: onTap != null,
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimals ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
        ),
      ],
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: theme.textPrimary,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        border: InputBorder.none,
        fillColor: Colors.transparent,
        filled: true,
        hintStyle: TextStyle(
          color: theme.textSecondary,  // textHint gibts nicht, nutze textSecondary
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}