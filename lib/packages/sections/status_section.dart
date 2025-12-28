// ═══════════════════════════════════════════════════════════════════════════
// lib/packages/sections/status_section.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/constants.dart';
import 'package:saegewerk/packages/sections/section_container.dart';

import '../../core/theme/theme_provider.dart';

import '../services/package_service.dart';


class StatusSection extends StatelessWidget {
  final String barcode;
  final TextEditingController zustandController;
  final TextEditingController statusController;
  final Map<String, dynamic> packageData;
  final PackageService packageService;
  final int userGroup;
  final VoidCallback? onStatusChanged;

  const StatusSection({
    super.key,
    required this.barcode,
    required this.zustandController,
    required this.statusController,
    required this.packageData,
    required this.packageService,
    required this.userGroup,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SectionContainer(
      children: [
        _buildZustandSelector(context, theme),
        const SizedBox(height: 16),
        _buildStatusDisplay(theme),
        const SizedBox(height: 16),
        if (userGroup >= 2) _buildActionButtons(context, theme),
      ],
    );
  }

  Widget _buildZustandSelector(BuildContext context, ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zustand',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildZustandChip(
                context: context,
                theme: theme,
                label: 'Frisch',
                value: PackageZustand.frisch,
                icon: Icons.water_drop,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildZustandChip(
                context: context,
                theme: theme,
                label: 'Trocken',
                value: PackageZustand.trocken,
                icon: Icons.wb_sunny,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZustandChip({
    required BuildContext context,
    required ThemeProvider theme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = zustandController.text == value;

    return GestureDetector(
      onTap: () {
        zustandController.text = value;
        (context as Element).markNeedsBuild();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : theme.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : theme.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay(ThemeProvider theme) {
    final status = statusController.text;
    final statusInfo = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusInfo.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(statusInfo.icon, color: statusInfo.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktueller Status',
                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  statusInfo.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: statusInfo.color,
                  ),
                ),
                if (_getStatusDate() != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getStatusDate()!,
                    style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeProvider theme) {
    final status = statusController.text;

    if (status == PackageStatus.ausgebucht) {
      return _buildResetButton(context, theme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aktionen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (status != PackageStatus.verkauft)
              Expanded(
                child: _buildActionButton(
                  context: context,
                  theme: theme,
                  label: 'Verkaufen',
                  icon: Icons.sell,
                  color: Colors.green,
                  onTap: () => _confirmAction(
                    context,
                    theme,
                    'Als verkauft markieren?',
                        () async {
                      await packageService.markAsVerkauft(barcode);
                      statusController.text = PackageStatus.verkauft;
                      onStatusChanged?.call();
                      showAppSnackbar(context, 'Paket als verkauft markiert');
                    },
                  ),
                ),
              ),
            if (status != PackageStatus.verkauft) const SizedBox(width: 12),
            if (status != PackageStatus.verarbeitet)
              Expanded(
                child: _buildActionButton(
                  context: context,
                  theme: theme,
                  label: 'Verarbeitet',
                  icon: Icons.build,
                  color: Colors.blue,
                  onTap: () => _confirmAction(
                    context,
                    theme,
                    'Als verarbeitet markieren?',
                        () async {
                      await packageService.markAsVerarbeitet(barcode);
                      statusController.text = PackageStatus.verarbeitet;
                      onStatusChanged?.call();
                      showAppSnackbar(context, 'Paket als verarbeitet markiert');
                    },
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            context: context,
            theme: theme,
            label: 'Ausbuchen',
            icon: Icons.logout,
            color: Colors.red,
            onTap: () => _confirmAction(
              context,
              theme,
              'Paket ausbuchen?\nDas Paket wird aus dem Lagerbestand entfernt.',
                  () async {
                await packageService.markAsAusgebucht(barcode);
                statusController.text = PackageStatus.ausgebucht;
                onStatusChanged?.call();
                showAppSnackbar(context, 'Paket ausgebucht');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(BuildContext context, ThemeProvider theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status zurücksetzen',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: _buildActionButton(
            context: context,
            theme: theme,
            label: 'Zurück ins Lager',
            icon: Icons.undo,
            color: theme.primary,
            onTap: () => _confirmAction(
              context,
              theme,
              'Status zurücksetzen?\nDas Paket wird wieder als "im Lager" markiert.',
                  () async {
                await packageService.resetStatus(barcode);
                statusController.text = PackageStatus.imLager;
                onStatusChanged?.call();
                showAppSnackbar(context, 'Status zurückgesetzt');
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required ThemeProvider theme,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAction(
      BuildContext context,
      ThemeProvider theme,
      String message,
      VoidCallback onConfirm,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        title: Text('Bestätigung', style: TextStyle(color: theme.textPrimary)),
        content: Text(message, style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );
  }

  
  _StatusInfo _getStatusInfo(String status) {
    switch (status) {
      case PackageStatus.verkauft:
        return _StatusInfo('Verkauft', Icons.sell, Colors.green);
      case PackageStatus.verarbeitet:
        return _StatusInfo('Verarbeitet', Icons.build, Colors.blue);
      case PackageStatus.ausgebucht:
        return _StatusInfo('Ausgebucht', Icons.logout, Colors.red);
      default:
        return _StatusInfo('Im Lager', Icons.inventory_2, Colors.grey);
    }
  }

  String? _getStatusDate() {
    final status = statusController.text;
    switch (status) {
      case PackageStatus.verkauft:
        return packageData['verkauftAm'] != null ? 'am ${packageData['verkauftAm']}' : null;
      case PackageStatus.verarbeitet:
        return packageData['verarbeitetAm'] != null ? 'am ${packageData['verarbeitetAm']}' : null;
      case PackageStatus.ausgebucht:
        return packageData['ausgebuchtAm'] != null ? 'am ${packageData['ausgebuchtAm']}' : null;
      default:
        return null;
    }
  }
}

class _StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  _StatusInfo(this.label, this.icon, this.color);
}