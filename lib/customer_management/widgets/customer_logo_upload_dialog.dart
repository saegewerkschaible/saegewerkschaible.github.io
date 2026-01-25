// lib/customer_management/widgets/customer_logo_upload_dialog.dart
// ═══════════════════════════════════════════════════════════════════════════
// CUSTOMER LOGO UPLOAD DIALOG
// Dialog zum Hochladen und Vorschau von Kundenlogos
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/services/customer_logo_service.dart';

class CustomerLogoUploadDialog extends StatefulWidget {
  final String customerId;
  final String? currentLogoUrl;

  const CustomerLogoUploadDialog({
    Key? key,
    required this.customerId,
    this.currentLogoUrl,
  }) : super(key: key);

  /// Zeigt den Dialog an
  static Future<bool?> show(
      BuildContext context, {
        required String customerId,
        String? currentLogoUrl,
      }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CustomerLogoUploadDialog(
        customerId: customerId,
        currentLogoUrl: currentLogoUrl,
      ),
    );
  }

  @override
  State<CustomerLogoUploadDialog> createState() => _CustomerLogoUploadDialogState();
}

class _CustomerLogoUploadDialogState extends State<CustomerLogoUploadDialog> {
  Uint8List? _originalBytes;
  Uint8List? _colorPreview;
  Uint8List? _bwPreview;
  bool _invertBw = false;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Dialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isWideScreen ? 600 : double.infinity,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(theme),

            Divider(height: 1, color: theme.border),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Aktuelles Logo (falls vorhanden)
                    if (widget.currentLogoUrl != null && _originalBytes == null)
                      _buildCurrentLogo(theme),

                    // Bild auswählen
                    _buildImagePicker(theme),

                    // Vorschau
                    if (_colorPreview != null && _bwPreview != null) ...[
                      const SizedBox(height: 24),
                      _buildPreviewSection(theme, isWideScreen),
                    ],

                    // Fehler
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.error),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: theme.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: theme.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            Divider(height: 1, color: theme.border),

            // Actions
            _buildActions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image, color: theme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kundenlogo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                Text(
                  'Für Lieferschein & Paketzettel',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.textSecondary),
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLogo(ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: theme.success, size: 18),
              const SizedBox(width: 8),
              Text(
                'Aktuelles Logo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 80),
              child: Image.network(
                widget.currentLogoUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image,
                  color: theme.textSecondary,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _originalBytes == null ? 'Bild auswählen' : 'Anderes Bild wählen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPickerButton(
                theme: theme,
                icon: Icons.photo_library,
                label: 'Galerie',
                onTap: () => _pickImage(fromCamera: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPickerButton(
                theme: theme,
                icon: Icons.camera_alt,
                label: 'Kamera',
                onTap: () => _pickImage(fromCamera: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPickerButton({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: theme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(ThemeProvider theme, bool isWideScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vorschau',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),

        // Previews nebeneinander oder untereinander
        isWideScreen
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildColorPreview(theme)),
            const SizedBox(width: 16),
            Expanded(child: _buildBwPreview(theme)),
          ],
        )
            : Column(
          children: [
            _buildColorPreview(theme),
            const SizedBox(height: 16),
            _buildBwPreview(theme),
          ],
        ),
      ],
    );
  }

  Widget _buildColorPreview(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description, color: theme.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Lieferschein (Farbe)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            alignment: Alignment.center,
            child: _isLoading
                ? CircularProgressIndicator(color: theme.primary, strokeWidth: 2)
                : Image.memory(
              _colorPreview!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Max. 400×200 px',
            style: TextStyle(fontSize: 10, color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBwPreview(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_shipping, color: theme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Paketzettel (S/W)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            alignment: Alignment.center,
            child: _isLoading
                ? CircularProgressIndicator(color: theme.primary, strokeWidth: 2)
                : Image.memory(
              _bwPreview!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Max. 200×100 px',
            style: TextStyle(fontSize: 10, color: theme.textSecondary),
          ),

          // Invertieren Toggle
          const SizedBox(height: 12),
          InkWell(
            onTap: _toggleInvert,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _invertBw ? theme.primary.withOpacity(0.1) : theme.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _invertBw ? theme.primary : theme.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _invertBw ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 18,
                    color: _invertBw ? theme.primary : theme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Farben invertieren',
                    style: TextStyle(
                      fontSize: 12,
                      color: _invertBw ? theme.primary : theme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Für dunkle Logos auf hellem Hintergrund',
            style: TextStyle(fontSize: 10, color: theme.textSecondary),
          ),
        ],
      ),
    );
  }
  Widget _buildActions(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Löschen-Button (falls Logo vorhanden) - nur Icon
          if (widget.currentLogoUrl != null)
            IconButton(
              onPressed: _isUploading ? null : _deleteLogo,
              icon: Icon(Icons.delete_outline, color: theme.error),
              tooltip: 'Logo löschen',
            ),

          const Spacer(),

          // Abbrechen
          TextButton(
            onPressed: _isUploading ? null : () => Navigator.pop(context, false),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),

          const SizedBox(width: 8),

          // Speichern - ohne Icon, kompakter
          ElevatedButton(
            onPressed: (_originalBytes != null && !_isUploading) ? _uploadLogo : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: theme.primary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isUploading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Speichern'),
          ),
        ],
      ),
    );
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _pickImage({required bool fromCamera}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes = await CustomerLogoService.pickImage(fromCamera: fromCamera);

      if (bytes == null) {
        setState(() => _isLoading = false);
        return;
      }

      _originalBytes = bytes;
      await _generatePreview();
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Laden des Bildes';
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePreview() async {
    if (_originalBytes == null) return;

    setState(() => _isLoading = true);

    try {
      final preview = await CustomerLogoService.generatePreview(
        imageBytes: _originalBytes!,
        invertBw: _invertBw,
      );

      if (preview != null) {
        setState(() {
          _colorPreview = preview['color'];
          _bwPreview = preview['bw'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Bild konnte nicht verarbeitet werden';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler bei der Bildverarbeitung';
        _isLoading = false;
      });
    }
  }

  void _toggleInvert() {
    setState(() => _invertBw = !_invertBw);
    _generatePreview();
  }

  Future<void> _uploadLogo() async {
    if (_originalBytes == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final result = await CustomerLogoService.uploadLogo(
        customerId: widget.customerId,
        imageBytes: _originalBytes!,
        invertBw: _invertBw,
      );

      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Logo erfolgreich gespeichert'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          );
        }
      } else {
        setState(() {
          _error = result['error'] ?? 'Upload fehlgeschlagen';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Fehler beim Hochladen: $e';
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteLogo() async {
    final theme = context.read<ThemeProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Logo löschen?', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'Das Kundenlogo wird unwiderruflich gelöscht.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);

      final success = await CustomerLogoService.deleteLogo(widget.customerId);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Logo gelöscht'),
              backgroundColor: theme.success,
            ),
          );
        } else {
          setState(() {
            _error = 'Fehler beim Löschen';
            _isUploading = false;
          });
        }
      }
    }
  }
}