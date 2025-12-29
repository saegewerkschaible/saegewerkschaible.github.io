// lib/screens/DeliveryNotes/delivery_note_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';

import '../../services/icon_helper.dart';

import 'widgets/package_card.dart';
import 'widgets/info_chips.dart';
import 'dialogs/delete_package_dialog.dart';
import 'dialogs/delete_delivery_note_dialog.dart';

class DeliveryNoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> deliveryNote;

  const DeliveryNoteDetailScreen({
    Key? key,
    required this.deliveryNote,
  }) : super(key: key);

  @override
  State<DeliveryNoteDetailScreen> createState() =>
      _DeliveryNoteDetailScreenState();
}

class _DeliveryNoteDetailScreenState extends State<DeliveryNoteDetailScreen> {
  Stream<QuerySnapshot> getPackagesForDeliveryNote() {
    final items = widget.deliveryNote['items'] as List<dynamic>;
    final packageIds =
    items.map((item) => item['packageId'].toString()).toList();

    if (packageIds.isEmpty) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance

        .collection('packages')
        .where(FieldPath.documentId, whereIn: packageIds)
        .snapshots();
  }

  Map<String, dynamic>? _findMatchingItem(String packageId) {
    final items = widget.deliveryNote['items'] as List<dynamic>? ?? [];
    for (var item in items) {
      if (item['packageId'].toString() == packageId) {
        return item as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final DateFormat formatter = DateFormat('dd.MM.yyyy HH:mm');

    final DateTime? createdAt =
    (widget.deliveryNote['createdAt'] as Timestamp?)?.toDate();
    final String number = widget.deliveryNote['number'] ?? '';
    final String customerName = widget.deliveryNote['customerName'] ?? '';
    final double totalVolume =
        (widget.deliveryNote['totalVolume'] as num?)?.toDouble() ?? 0.0;
    final int totalQuantity = widget.deliveryNote['totalQuantity'] ?? 0;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: getAdaptiveIcon(
                iconName: 'receipt_long',
                defaultIcon: Icons.receipt_long,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Lieferschein $number',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: getAdaptiveIcon(
              iconName: 'delete',
              defaultIcon: Icons.delete,
              color: colors.error,
            ),
            onPressed: () => DeleteDeliveryNoteDialog.show(
              context,
              deliveryNote: widget.deliveryNote,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          _buildHeader(
            context,
            colors,
            customerName,
            createdAt,
            formatter,
            totalQuantity,
            totalVolume,
          ),

          // Pakete Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getPackagesForDeliveryNote(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Fehler: ${snapshot.error}',
                      style: TextStyle(color: colors.error),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.primary),
                  );
                }

                final packages = snapshot.data?.docs ?? [];

                if (packages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        getAdaptiveIcon(
                          iconName: 'inventory',
                          defaultIcon: Icons.inventory,
                          size: 64,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Pakete gefunden',
                          style: TextStyle(
                            fontSize: 18,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: packages.length,
                  itemBuilder: (context, index) {
                    final package =
                    packages[index].data() as Map<String, dynamic>;
                    final packageId = packages[index].id;
                    final isEven = index % 2 == 0;

                    return PackageCard(
                      package: package,
                      packageId: packageId,
                      matchingItem: _findMatchingItem(packageId),
                      index: index,
                      isEven: isEven,
                      onDelete: () => DeletePackageDialog.show(
                        context,
                        packageId: packageId,
                        deliveryNote: widget.deliveryNote,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      dynamic colors,
      String customerName,
      DateTime? createdAt,
      DateFormat formatter,
      int totalQuantity,
      double totalVolume,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withOpacity(0.05),
            colors.primary.withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kunde und Datum
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: getAdaptiveIcon(
                  iconName: 'person',
                  defaultIcon: Icons.person,
                  size: 20,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kunde',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            createdAt != null ? formatter.format(createdAt) : '',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          // Trennlinie
          Divider(color: colors.border, height: 1),

          const SizedBox(height: 16),

          // Info Cards
          Row(
            children: [
              Expanded(
                child: _ModernInfoCard(
                  label: 'Pakete',
                  value:
                  '${(widget.deliveryNote['items'] as List<dynamic>?)?.length ?? 0}',
                  icon: Icons.inventory_2,
                  iconName: 'inventory_2',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernInfoCard(
                  label: 'Stk.',
                  value: '$totalQuantity',
                  icon: Icons.format_list_numbered,
                  iconName: 'format_list_numbered',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModernInfoCard(
                  label: 'Vol.',
                  value: '${totalVolume.toStringAsFixed(1)} m³',
                  icon: Icons.view_in_ar,
                  iconName: 'view_in_ar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String iconName;

  const _ModernInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconName,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              getAdaptiveIcon(
                iconName: iconName,
                defaultIcon: icon,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}