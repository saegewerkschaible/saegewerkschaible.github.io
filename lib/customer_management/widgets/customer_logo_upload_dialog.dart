// lib/customer_management/widgets/customer_logo_upload_dialog.dart
// ═══════════════════════════════════════════════════════════════════════════
// CUSTOMER LOGO UPLOAD DIALOG
// Dialog zum Hochladen und Vorschau von Kundenlogos
// WEB-KOMPATIBEL: Kamera ausgeblendet auf Web
// ═══════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  State<CustomerLogoUploadDialog> createState() =>
      _CustomerLogoUploadDialogState();
}

class _CustomerLogoUploadDialogState extends State<CustomerLogoUploadDialog> {
  Uint8List? _originalBytes;
  Uint8List? _colorPreview;
  Uint8List? _bwPreview;
  Uint8List? _customBwBytes;  // NEU: Individuelles S/W Bild
  bool _useCustomBw = false;   // NEU: Flag ob individuelles Bild verwendet wird

  bool _invertBw = false;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 [CustomerLogoUploadDialog] initState');
    debugPrint('   Platform: ${kIsWeb ? "Web" : "Mobile"}');
    debugPrint('   CustomerId: ${widget.customerId}');
    debugPrint('   CurrentLogoUrl: ${widget.currentLogoUrl}');
  }

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
                    // Web-Hinweis
                    if (kIsWeb) _buildWebHint(theme),

                    // Aktuelles Logo (falls vorhanden)
                    if (widget.currentLogoUrl != null && _originalBytes == null)
                      _buildCurrentLogo(theme),

                    // Bild auswählen
                    _buildImagePicker(theme),

                    // Loading Indicator
                    if (_isLoading) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: theme.primary),
                            const SizedBox(height: 12),
                            Text(
                              'Bild wird verarbeitet...',
                              style: TextStyle(color: theme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Vorschau
                    if (_colorPreview != null &&
                        _bwPreview != null &&
                        !_isLoading) ...[
                      const SizedBox(height: 24),
                      _buildPreviewSection(theme, isWideScreen),
                    ],

                    // Fehler
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBox(theme),
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

  Widget _buildWebHint(ThemeProvider theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.info, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Du verwendest die Web-Version. Bitte wähle ein Bild aus deinen Dateien.',
              style: TextStyle(color: theme.info, fontSize: 13),
            ),
          ),
        ],
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
                errorBuilder: (_, error, ___) {
                  debugPrint('❌ [CustomerLogoUploadDialog] Bild laden fehlgeschlagen: $error');
                  return Icon(
                    Icons.broken_image,
                    color: theme.textSecondary,
                    size: 48,
                  );
                },
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 48,
                    width: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primary,
                    ),
                  );
                },
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
        // Auf Web nur Galerie-Button anzeigen
        if (kIsWeb)
          _buildPickerButton(
            theme: theme,
            icon: Icons.folder_open,
            label: 'Datei auswählen',
            onTap: () => _pickImage(fromCamera: false),
            fullWidth: true,
          )
        else
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
    bool fullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading || _isUploading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: theme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: theme.primary, size: 24),
              ),
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
      ),
    );
  }

  Widget _buildErrorBox(ThemeProvider theme) {
    return Container(
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
          IconButton(
            icon: Icon(Icons.close, color: theme.error, size: 18),
            onPressed: () => setState(() => _error = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
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
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.description, size: 16, color: theme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Lieferschein (Farbe)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.border),
            ),
            child: _colorPreview == null
                ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary,
              ),
            )
                : Image.memory(
              _colorPreview!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Max. 600×300 px',
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
        color: theme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 16, color: theme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Paketzettel (S/W)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.border),
            ),
            child: _bwPreview == null
                ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.primary,
              ),
            )
                : Image.memory(
              _bwPreview!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Max. 400×200 px',
            style: TextStyle(fontSize: 10, color: theme.textSecondary),
          ),

    // Individuelles S/W Bild hochladen Button
    const SizedBox(height: 12),
    OutlinedButton.icon(
    onPressed: _isLoading ? null : _pickCustomBwImage,
    icon: Icon(
    _useCustomBw ? Icons.check_circle : Icons.upload_file,
    size: 16,
    color: _useCustomBw ? theme.success : theme.primary,
    ),
    label: Text(
    _useCustomBw ? 'Eigenes S/W Bild aktiv' : 'Eigenes S/W Bild',
    style: TextStyle(
    fontSize: 12,
    color: _useCustomBw ? theme.success : theme.primary,
    ),
    ),
    style: OutlinedButton.styleFrom(
    side: BorderSide(
    color: _useCustomBw ? theme.success : theme.border,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    ),

// Invertieren Toggle - NUR zeigen wenn KEIN custom Bild
    if (!_useCustomBw) ...[
    const SizedBox(height: 12), Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _toggleInvert,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                  _invertBw ? theme.primary.withOpacity(0.1) : theme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _invertBw ? theme.primary : theme.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _invertBw
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
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
          ),
        ],
          const SizedBox(height: 4),



          Text(
            'Für dunkle Logos auf hellem Hintergrund',
            style: TextStyle(fontSize: 10, color: theme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomBwImage() async {
    final bytes = await CustomerLogoService.pickImage(fromCamera: false);

    if (bytes == null) return;

    // S/W Version generieren (nur resize, kein Farbumwandlung nötig wenn schon S/W)
    final preview = await CustomerLogoService.generateBwPreview(imageBytes: bytes);

    if (preview != null) {
      setState(() {
        _customBwBytes = preview;
        _bwPreview = preview;
        _useCustomBw = true;
      });
    }
  }
  Widget _buildActions(ThemeProvider theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Löschen-Button (falls Logo vorhanden)
          if (widget.currentLogoUrl != null)
            IconButton(
              onPressed: _isUploading ? null : _deleteLogo,
              icon: Icon(Icons.delete_outline, color: theme.error),
              tooltip: 'Logo löschen',
            ),

          const Spacer(),

          // Abbrechen
          TextButton(
            onPressed:
            _isUploading ? null : () => Navigator.pop(context, false),
            child:
            Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),

          const SizedBox(width: 8),

          // Speichern
          ElevatedButton(
            onPressed:
            (_originalBytes != null && !_isUploading && !_isLoading)
                ? _uploadLogo
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: theme.primary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: _isUploading
                ? const SizedBox(
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
    debugPrint('🔄 [CustomerLogoUploadDialog] _pickImage(fromCamera: $fromCamera)');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes =
      await CustomerLogoService.pickImage(fromCamera: fromCamera);

      if (bytes == null) {
        debugPrint('ℹ️ [CustomerLogoUploadDialog] Keine Bytes erhalten');
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('✅ [CustomerLogoUploadDialog] Bytes erhalten: ${bytes.length}');
      _originalBytes = bytes;
      await _generatePreview();
    } catch (e) {
      debugPrint('❌ [CustomerLogoUploadDialog] Fehler: $e');
      setState(() {
        _error = 'Fehler beim Laden des Bildes: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generatePreview() async {
    if (_originalBytes == null) return;

    debugPrint('🔄 [CustomerLogoUploadDialog] _generatePreview()');
    setState(() => _isLoading = true);

    try {
      final preview = await CustomerLogoService.generatePreview(
        imageBytes: _originalBytes!,
        invertBw: _invertBw,
      );

      if (preview != null) {
        debugPrint('✅ [CustomerLogoUploadDialog] Vorschau generiert');
        setState(() {
          _colorPreview = preview['color'];
          _bwPreview = preview['bw'];
          _isLoading = false;
        });
      } else {
        debugPrint('❌ [CustomerLogoUploadDialog] Vorschau null');
        setState(() {
          _error = 'Bild konnte nicht verarbeitet werden. Versuche ein anderes Format (PNG/JPG).';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CustomerLogoUploadDialog] Fehler bei Vorschau: $e');
      setState(() {
        _error = 'Fehler bei der Bildverarbeitung: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleInvert() {
    debugPrint('🔄 [CustomerLogoUploadDialog] _toggleInvert()');
    setState(() => _invertBw = !_invertBw);
    _generatePreview();
  }

  Future<void> _uploadLogo() async {
    if (_originalBytes == null) return;

    debugPrint('🔄 [CustomerLogoUploadDialog] _uploadLogo()');

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final result = await CustomerLogoService.uploadLogo(
        customerId: widget.customerId,
        imageBytes: _originalBytes!,
        invertBw: _invertBw,
        customBwBytes: _useCustomBw ? _customBwBytes : null,  // NEU
      );

      if (result['success'] == true) {
        debugPrint('✅ [CustomerLogoUploadDialog] Upload erfolgreich');
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
        debugPrint('❌ [CustomerLogoUploadDialog] Upload fehlgeschlagen: ${result['error']}');
        setState(() {
          _error = result['error'] ?? 'Upload fehlgeschlagen';
          _isUploading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [CustomerLogoUploadDialog] Exception: $e');
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
        title:
        Text('Logo löschen?', style: TextStyle(color: theme.textPrimary)),
        content: Text(
          'Das Kundenlogo wird unwiderruflich gelöscht.',
          style: TextStyle(color: theme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
            Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
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