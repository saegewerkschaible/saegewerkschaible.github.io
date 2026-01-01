// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/dialogs/custom_keyboard_dialog.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

/// Zeigt einen benutzerdefinierten Numpad-Dialog für Texteingabe
/// Unterstützt Zahlen, Bindestrich, Unterstrich und Punkt
///
/// [controller] - TextEditingController für den Eingabewert
/// [onValueChanged] - Optionaler Callback wenn ein Wert übernommen wird
Future<void> showCustomKeyboardDialog({

  required BuildContext context,
  required TextEditingController controller,
  VoidCallback? onValueChanged,
}) {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return _CustomKeyboardDialog(
        controller: controller,
        onValueChanged: onValueChanged,
      );
    },
  );
}

class _CustomKeyboardDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback? onValueChanged;

  const _CustomKeyboardDialog({
    required this.controller,
    this.onValueChanged,
  });

  @override
  State<_CustomKeyboardDialog> createState() => _CustomKeyboardDialogState();
}

class _CustomKeyboardDialogState extends State<_CustomKeyboardDialog> {
  late String currentInput;

  @override
  void initState() {
    super.initState();
    currentInput = widget.controller.text;
  }

  void _updateInput(String value) {
    setState(() {
      currentInput += value;
    });
  }

  void _deleteLastChar() {
    setState(() {
      if (currentInput.isNotEmpty) {
        currentInput = currentInput.substring(0, currentInput.length - 1);
      }
    });
  }

  void _clearInput() {
    setState(() {
      currentInput = '';
    });
  }

  void _confirmInput() {
    widget.controller.text = currentInput;
    Navigator.pop(context);
    widget.onValueChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: theme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = math.min(constraints.maxWidth, 500.0);
          const spacing = 8.0;
          final buttonSize = (availableWidth - 32 - (3 * spacing)) / 4;

          return Container(
            width: availableWidth,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDisplay(theme, buttonSize),
                const SizedBox(height: 20),
                _buildNumpad(theme, buttonSize, spacing),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisplay(ThemeProvider theme, double buttonSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Text(
        currentInput,
        style: TextStyle(
          fontSize: math.max(20, buttonSize * 0.4),
          fontWeight: FontWeight.bold,
          color: theme.textPrimary,
        ),
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildNumpad(ThemeProvider theme, double buttonSize, double spacing) {
    return Column(
      children: [
        // Erste Reihe
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton('7', () => _updateInput('7'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('8', () => _updateInput('8'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('9', () => _updateInput('9'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('-', () => _updateInput('-'), buttonSize, theme, isSpecial: true),
          ],
        ),
        SizedBox(height: spacing),

        // Zweite Reihe
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton('4', () => _updateInput('4'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('5', () => _updateInput('5'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('6', () => _updateInput('6'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('_', () => _updateInput('_'), buttonSize, theme, isSpecial: true),
          ],
        ),
        SizedBox(height: spacing),

        // Dritte Reihe
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton('1', () => _updateInput('1'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('2', () => _updateInput('2'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('3', () => _updateInput('3'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('.', () => _updateInput('.'), buttonSize, theme, isSpecial: true),
          ],
        ),
        SizedBox(height: spacing),

        // Vierte Reihe
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildButton('C', _clearInput, buttonSize, theme, actionColor: theme.error),
            SizedBox(width: spacing),
            _buildButton('0', () => _updateInput('0'), buttonSize, theme),
            SizedBox(width: spacing),
            _buildButton('⌫', _deleteLastChar, buttonSize, theme, isAction: true),
            SizedBox(width: spacing),
            _buildButton('✓', _confirmInput, buttonSize, theme, actionColor: theme.success),
          ],
        ),
      ],
    );
  }

  Widget _buildButton(
      String label,
      VoidCallback onTap,
      double size,
      ThemeProvider theme, {
        bool isSpecial = false,
        bool isAction = false,
        Color? actionColor,
      }) {
    Color bgColor;
    Color textColor;

    if (actionColor != null) {
      bgColor = actionColor;
      textColor = theme.surface;
    } else if (isSpecial) {
      bgColor = theme.primary;
      textColor = Colors.white;
    } else if (isAction) {
      bgColor = theme.background;
      textColor = theme.textPrimary;
    } else {
      bgColor = theme.background;
      textColor = theme.textPrimary;
    }

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 2,
          shadowColor: Colors.black26,  // shadow gibt's nicht im ThemeProvider
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}