// ═══════════════════════════════════════════════════════════════════════════
// lib/widgets/dialogs/dimension_input_dialog.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

/// Zeigt einen Dialog zur Dimensionseingabe mit Taschenrechner und Schnellauswahl
///
/// [controller] - TextEditingController für den Eingabewert
/// [title] - Titel des Dialogs (z.B. "Länge [m]", "Breite [mm]")
/// [quickOptions] - Liste der Schnellauswahl-Optionen
/// [onValueChanged] - Callback wenn ein Wert übernommen wird
/// [maxValue] - Optionaler Maximalwert für Validierung
/// [maxValueMessage] - Fehlermeldung bei Überschreitung des Maximalwerts
void showDimensionInputDialog({
  required BuildContext context,
  required TextEditingController controller,
  required String title,
  required List<String> quickOptions,
  required VoidCallback onValueChanged,
  double? maxValue,
  String? maxValueMessage,
  Function(String message)? onValidationError,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return _DimensionInputDialog(
        controller: controller,
        title: title,
        quickOptions: quickOptions,
        onValueChanged: onValueChanged,
        maxValue: maxValue,
        maxValueMessage: maxValueMessage,
        onValidationError: onValidationError,
      );
    },
  );
}

class _DimensionInputDialog extends StatefulWidget {
  final TextEditingController controller;
  final String title;
  final List<String> quickOptions;
  final VoidCallback onValueChanged;
  final double? maxValue;
  final String? maxValueMessage;
  final Function(String message)? onValidationError;

  const _DimensionInputDialog({
    required this.controller,
    required this.title,
    required this.quickOptions,
    required this.onValueChanged,
    this.maxValue,
    this.maxValueMessage,
    this.onValidationError,
  });

  @override
  State<_DimensionInputDialog> createState() => _DimensionInputDialogState();
}

class _DimensionInputDialogState extends State<_DimensionInputDialog> {
  late String currentNumber;
  late String calculation;
  late bool isNewCalculation;
  late String result;
  late String displayText;

  @override
  void initState() {
    super.initState();
    currentNumber = widget.controller.text.isEmpty ? '' : widget.controller.text;
    calculation = '';
    isNewCalculation = true;
    result = currentNumber.isEmpty ? '0' : currentNumber;
    displayText = result;
  }

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
              ? currentNumber
              : _calculateResult(calculation, currentNumber);
        }
      }
    });
  }

  void _handleConfirm() {
    // Validierung
    if (widget.maxValue != null) {
      try {
        double value = double.parse(result);
        if (value > widget.maxValue!) {
          widget.onValidationError?.call(
            widget.maxValueMessage ?? "Der Wert darf nicht größer als ${widget.maxValue} sein",
          );
          return;
        }
      } catch (e) {
        widget.onValidationError?.call("Ungültige Eingabe");
        return;
      }
    }

    widget.controller.text = result;
    Navigator.pop(context);
    widget.onValueChanged();
  }

  void _selectQuickOption(String option) {
    widget.controller.text = option;
    Navigator.pop(context);
    widget.onValueChanged();
  }

  @override
  Widget build(BuildContext context) {

    final theme = Provider.of<ThemeProvider>(context);
    return OrientationBuilder(
      builder: (context, orientation) {
        bool isLandscape = orientation == Orientation.landscape;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: theme.surface,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double maxDialogWidth = constraints.maxWidth;
              double minDialogWidth = math.max(350.0, constraints.maxWidth * 0.5);
              double dialogWidth = math.min(maxDialogWidth, math.max(minDialogWidth, constraints.maxWidth * 0.8));

              if (constraints.maxWidth > 600) {
                dialogWidth = math.min(700.0, constraints.maxWidth * 0.8);
              }

              double buttonSize = math.min(
                ((dialogWidth - 80) / 4) - 5,
                80.0,
              );
              double fontSize = buttonSize * 0.4;
              double displayFontSize = math.min(32.0, buttonSize * 0.6);

              Widget quickSelectionWidget = _buildQuickSelection(
                theme: theme,
                isLandscape: isLandscape,
                dialogWidth: dialogWidth,
              );

              Widget calculatorWidget = _buildCalculator(
                theme: theme,
                buttonSize: buttonSize,
                fontSize: fontSize,
                displayFontSize: displayFontSize,
              );

              if (isLandscape) {
                return Container(
                  // Wir erzwingen eine feste Breite für das Tablet-Fenster
                  width: math.min(800, constraints.maxWidth * 0.9),
                  // Wir erzwingen eine feste Höhe
                  height: 600,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.surface,
                  ),
                  child: Row(
                    // stretch sorgt dafür, dass beide Seiten die vollen 500px Höhe nutzen
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Linke Seite: Schnellauswahl (Breite fest auf 300px)
                      SizedBox(
                        width: 300,
                        child: _buildQuickSelection(
                          theme: theme,
                          isLandscape: isLandscape,
                          dialogWidth: 300, // Hier die feste Breite übergeben
                        ),
                      ),
                      // Trennlinie
                      Container(width: 1, color: theme.border),
                      // Rechte Seite: Taschenrechner (nimmt den restlichen Platz)
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: calculatorWidget,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }else {
                return Container(
                  width: dialogWidth,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.surface,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        calculatorWidget,
                        Container(height: 1, color: theme.border),
                        quickSelectionWidget,
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
  Widget _buildQuickSelection({
    required ThemeProvider theme,
    required bool isLandscape,
    required double dialogWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            "Schnellauswahl",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              // Clip verhindert, dass Ecken aus dem Rahmen schauen
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Titel-Header (Blau)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: theme.primary,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textOnPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Das neue Grid für die Zahlen
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,       // 2 Spalten
                        childAspectRatio: 2.2,   // Macht die Buttons angenehm breit
                        mainAxisSpacing: 0,
                        crossAxisSpacing: 0,
                      ),
                      itemCount: widget.quickOptions.length,
                      itemBuilder: (context, index) {
                        final option = widget.quickOptions[index];
                        bool isSelected = widget.controller.text == option;
                        return InkWell(
                          onTap: () => _selectQuickOption(option),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? theme.primary.withOpacity(0.12) : theme.surface,
                              border: Border.all(
                                color: theme.border.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 18, // Große Schrift für Tablet
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? theme.primary : theme.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCalculator({
    required ThemeProvider theme,
    required double buttonSize,
    required double fontSize,
    required double displayFontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display
          Container(
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
          ),
          const SizedBox(height: 16),

          // Buttons
          Column(
            children: [
              _buildButtonRow(['7', '8', '9', '×'], theme, buttonSize, fontSize),
              const SizedBox(height: 10),
              _buildButtonRow(['4', '5', '6', '+'], theme, buttonSize, fontSize),
              const SizedBox(height: 10),
              _buildButtonRow(['1', '2', '3', '0'], theme, buttonSize, fontSize),
              const SizedBox(height: 10),
              _buildButtonRow(['.', 'C', '⌫', '✓'], theme, buttonSize, fontSize),
            ],
          ),
        ],
      ),
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
        textColor = theme.textOnPrimary;
        onTap = () => _processOperation(label);
        break;
      case '.':
        bgColor = theme.textSecondary.withOpacity(0.3);
        textColor = theme.textPrimary;
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