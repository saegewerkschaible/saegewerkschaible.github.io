// lib/components/formatted_ip_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// IP-ADRESSE INPUT WIDGET
/// ═══════════════════════════════════════════════════════════════════════════

class IPAddressInput extends StatelessWidget {
  final String? value;
  final String label;
  final String? hint;
  final ValueChanged<String> onChanged;
  final bool enabled;

  const IPAddressInput({
    super.key,
    this.value,
    this.label = 'IP-Adresse',
    this.hint,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final hasValue = value != null && value!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled ? () => _showIPInputDialog(context) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: enabled ? theme.background : theme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: hasValue ? Colors.green : theme.textSecondary.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasValue ? value! : (hint ?? '192.168.178.xxx'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'monospace',
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                      color: hasValue ? theme.textPrimary : theme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: theme.textSecondary.withOpacity(0.4),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showIPInputDialog(BuildContext context) {
    // Parse existing value
    List<String> parts = ['', '', '', ''];
    if (value != null && value!.isNotEmpty) {
      final split = value!.split('.');
      for (int i = 0; i < split.length && i < 4; i++) {
        parts[i] = split[i];
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IPInputDialog(
        initialParts: parts,
        onSave: onChanged,
      ),
    );
  }
}

class _IPInputDialog extends StatefulWidget {
  final List<String> initialParts;
  final ValueChanged<String> onSave;

  const _IPInputDialog({
    required this.initialParts,
    required this.onSave,
  });

  @override
  State<_IPInputDialog> createState() => _IPInputDialogState();
}

class _IPInputDialogState extends State<_IPInputDialog> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (i) => TextEditingController(text: widget.initialParts[i]));
    _focusNodes = List.generate(4, (i) => FocusNode());

    // Auto-Focus erstes leeres Feld
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int focusIndex = _controllers.indexWhere((c) => c.text.isEmpty);
      if (focusIndex == -1) focusIndex = 0;
      _focusNodes[focusIndex].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _fullIP => _controllers.map((c) => c.text).join('.');

  bool get _isValid {
    for (var c in _controllers) {
      if (c.text.isEmpty) return false;
      final num = int.tryParse(c.text);
      if (num == null || num < 0 || num > 255) return false;
    }
    return true;
  }

  void _onFieldChanged(int index, String value) {
    // Validiere: nur Zahlen 0-255
    if (value.isNotEmpty) {
      final num = int.tryParse(value);
      if (num != null && num > 255) {
        _controllers[index].text = '255';
        _controllers[index].selection = TextSelection.fromPosition(
          const TextPosition(offset: 3),
        );
      }
    }

    // Auto-Jump zum nächsten Feld
    if (value.length == 3 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.wifi, color: theme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IP-Adresse eingeben',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    Text(
                      'Feste IP aus dem Router',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // IP Input Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    _buildOctetField(i, theme),
                    if (i < 3)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // Preview
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isValid ? Colors.green.withOpacity(0.1) : theme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isValid ? Colors.green : theme.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isValid ? Icons.check_circle : Icons.info_outline,
                    color: _isValid ? Colors.green : theme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isValid ? _fullIP : 'Bitte alle Felder ausfüllen (0-255)',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: _isValid ? 'monospace' : null,
                      fontWeight: _isValid ? FontWeight.w600 : FontWeight.normal,
                      color: _isValid ? Colors.green : theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textPrimary,
                      side: BorderSide(color: theme.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isValid
                        ? () {
                      widget.onSave(_fullIP);
                      Navigator.pop(context);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: theme.border,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Übernehmen',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOctetField(int index, ThemeProvider theme) {
    return SizedBox(
      width: 60,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 3,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          color: theme.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          filled: true,
          fillColor: theme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.primary, width: 2),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        onChanged: (v) => _onFieldChanged(index, v),
        onSubmitted: (_) {
          if (index < 3) {
            _focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }
}