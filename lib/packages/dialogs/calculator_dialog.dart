// ═══════════════════════════════════════════════════════════════════════════
// lib/shared/dialogs/calculator_dialog.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_provider.dart';

/// Zeigt einen einfachen Taschenrechner-Dialog
///
/// [controller] - TextEditingController für den Ergebniswert
/// [onValueChanged] - Callback wenn ein Wert übernommen wird
/// [allowDecimals] - Erlaubt Dezimalzahlen (default: true)
void showCalculatorDialog({
  required BuildContext context,
  required TextEditingController controller,
  required VoidCallback onValueChanged,
  bool allowDecimals = true,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _CalculatorDialog(
        controller: controller,
        onValueChanged: onValueChanged,
        allowDecimals: allowDecimals,
      );
    },
  );
}

class _CalculatorDialog extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onValueChanged;
  final bool allowDecimals;

  const _CalculatorDialog({
    required this.controller,
    required this.onValueChanged,
    required this.allowDecimals,
  });

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  String currentNumber = '';
  String calculation = '';
  bool isNewCalculation = true;
  String result = '0';
  String displayText = '0';

  String _calculateResult(String calc, String current) {
    if (calc.isEmpty && current.isEmpty) return '0';
    if (calc.isEmpty) return current;

    String fullCalc = calc;
    if (current.isNotEmpty) {
      fullCalc += ' $current';
    }

    List<String> parts = fullCalc.split(' ');

    if (parts.last == '+' || parts.last == '×') {
      parts.removeLast();
    }

    if (parts.length < 3) return parts[0];

    // Erst alle Multiplikationen (Punkt vor Strich)
    while (parts.contains('×')) {
      int index = parts.indexOf('×');
      if (index > 0 && index < parts.length - 1) {
        try {
          double num1 = double.parse(parts[index - 1]);
          double num2 = double.parse(parts[index + 1]);
          double result = num1 * num2;
          result = double.parse(result.toStringAsFixed(10));
          parts.removeRange(index - 1, index + 2);
          parts.insert(index - 1, result.toString());
        } catch (e) {
          break;
        }
      }
    }

    // Dann alle Additionen
    try {
      double finalResult = double.parse(parts[0]);
      for (int i = 1; i < parts.length - 1; i += 2) {
        if (parts[i] == '+') {
          finalResult += double.parse(parts[i + 1]);
        }
      }

      finalResult = double.parse(finalResult.toStringAsFixed(10));

      String resultStr = finalResult.toString();
      if (resultStr.contains('.')) {
        while (resultStr.endsWith('0')) {
          resultStr = resultStr.substring(0, resultStr.length - 1);
        }
        if (resultStr.endsWith('.')) {
          resultStr = resultStr.substring(0, resultStr.length - 1);
        }
      }

      return resultStr;
    } catch (e) {
      return parts[0];
    }
  }

  void _updateDisplay(String value) {
    setState(() {
      if (isNewCalculation) {
        currentNumber = value;
        isNewCalculation = false;
      } else {
        currentNumber += value;
      }
      if (calculation.isEmpty) {
        result = currentNumber;
      } else {
        result = _calculateResult(calculation, currentNumber);
      }
      displayText = result;
    });
  }

  void _processOperation(String op) {
    if (currentNumber.isEmpty && calculation.isEmpty) return;

    setState(() {
      if (calculation.isEmpty) {
        calculation = currentNumber;
      } else if (currentNumber.isNotEmpty) {
        calculation += ' $currentNumber';
        result = _calculateResult(calculation, '');
      }

      if (!calculation.endsWith(' ×') && !calculation.endsWith(' +')) {
        calculation += ' $op';
        currentNumber = '';
        isNewCalculation = true;
        displayText = result;
      }
    });
  }

  void _handleDecimal() {
    if (!widget.allowDecimals) return;
    setState(() {
      if (!currentNumber.contains('.')) {
        if (currentNumber.isEmpty) {
          currentNumber = '0.';
        } else {
          currentNumber += '.';
        }
        displayText = calculation.isEmpty
            ? currentNumber
            : _calculateResult(calculation, currentNumber);
      }
    });
  }

  void _handleClear() {
    setState(() {
      currentNumber = '';
      calculation = '';
      isNewCalculation = true;
      result = '0';
      displayText = '0';
    });
  }

  void _handleBackspace() {
    setState(() {
      if (currentNumber.isNotEmpty) {
        currentNumber = currentNumber.substring(0, currentNumber.length - 1);
        if (currentNumber.isEmpty && calculation.isEmpty) {
          displayText = '0';
        } else {
          displayText = calculation.isEmpty
              ? (currentNumber.isEmpty ? '0' : currentNumber)
              : _calculateResult(calculation, currentNumber);
        }
      }
    });
  }

  void _handleConfirm() {
    widget.controller.text = result;
    Navigator.pop(context);
    widget.onValueChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: theme.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double maxDialogWidth = math.min(500.0, constraints.maxWidth * 0.9);
          double minDialogWidth = math.max(350.0, constraints.maxWidth * 0.5);
          double dialogWidth = math.min(maxDialogWidth, math.max(minDialogWidth, constraints.maxWidth * 0.7));

          double buttonSize = math.min((dialogWidth - 48) / 4, 100.0);
          double fontSize = buttonSize * 0.4;
          double displayFontSize = math.min(32.0, buttonSize * 0.6);

          return Container(
            width: dialogWidth,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDisplay(theme, fontSize, displayFontSize),
                const SizedBox(height: 16),
                _buildButtons(theme, buttonSize, fontSize),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisplay(ThemeProvider theme, double fontSize, double displayFontSize) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            calculation + (currentNumber.isEmpty ? '' : ' $currentNumber'),
            style: TextStyle(
              color: theme.textSecondary,
              fontSize: fontSize,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: TextStyle(
              fontSize: displayFontSize,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(ThemeProvider theme, double buttonSize, double fontSize) {
    return Column(
      children: [
        _buildButtonRow(['7', '8', '9', '×'], theme, buttonSize, fontSize),
        SizedBox(height: buttonSize * 0.15),
        _buildButtonRow(['4', '5', '6', '+'], theme, buttonSize, fontSize),
        SizedBox(height: buttonSize * 0.15),
        _buildButtonRow(['1', '2', '3', '0'], theme, buttonSize, fontSize),
        SizedBox(height: buttonSize * 0.15),
        _buildButtonRow(['.', 'C', '⌫', '✓'], theme, buttonSize, fontSize),
      ],
    );
  }

  Widget _buildButtonRow(
      List<String> labels,
      ThemeProvider theme,
      double buttonSize,
      double fontSize,
      ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels.map((label) {
        return _buildCalcButton(
          label: label,
          theme: theme,
          size: buttonSize,
          fontSize: fontSize,
        );
      }).toList(),
    );
  }

  Widget _buildCalcButton({
    required String label,
    required ThemeProvider theme,
    required double size,
    required double fontSize,
  }) {
    Color bgColor;
    Color textColor;
    VoidCallback onTap;

    switch (label) {
      case '×':
      case '+':
        bgColor = theme.primary;
        textColor = Colors.white;
        onTap = () => _processOperation(label);
        break;
      case '.':
        bgColor = widget.allowDecimals
            ? theme.textSecondary.withOpacity(0.3)
            : theme.textSecondary.withOpacity(0.1);
        textColor = widget.allowDecimals
            ? theme.textPrimary
            : theme.textSecondary;
        onTap = _handleDecimal;
        break;
      case 'C':
        bgColor = theme.error.withOpacity(0.7);
        textColor = theme.surface;
        onTap = _handleClear;
        break;
      case '⌫':
        bgColor = theme.background;
        textColor = theme.textPrimary;
        onTap = _handleBackspace;
        break;
      case '✓':
        bgColor = theme.success;
        textColor = theme.surface;
        onTap = _handleConfirm;
        break;
      default: // Zahlen
        bgColor = theme.background;
        textColor = theme.textPrimary;
        onTap = () => _updateDisplay(label);
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
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}