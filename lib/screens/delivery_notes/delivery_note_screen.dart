// lib/screens/DeliveryNotes/delivery_note_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/services/filter/filter_settings.dart';

import '../../services/icon_helper.dart';

import 'models/layout_type.dart';
import 'widgets/delivery_note_card.dart';
import 'widgets/delivery_note_summary.dart';
import 'widgets/delivery_note_filters.dart';
import 'dialogs/filter_dialog.dart';

class DeliveryNoteScreen extends StatefulWidget {
  const DeliveryNoteScreen({Key? key}) : super(key: key);

  @override
  State<DeliveryNoteScreen> createState() => _DeliveryNoteScreenState();
}

class _DeliveryNoteScreenState extends State<DeliveryNoteScreen> {
  Stream<QuerySnapshot> getDeliveryNotes() {
    return FirebaseFirestore.instance

        .collection('delivery_notes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Provider.of<ThemeProvider>(context).colors;
    final filterSettings = Provider.of<FilterSettings>(context);
    final layoutType = context.layoutType;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
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
                color: Colors.white70
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Lieferscheine',
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
              iconName: 'filter_list',
              defaultIcon: Icons.filter_list,
              color: colors.primary,
            ),
            onPressed: () => FilterDialog.show(
              context,
              onApply: () => setState(() {}),
            ),
          ),
        ],
      ),
      body: _buildResponsiveLayout(layoutType, filterSettings, colors),
    );
  }

  Widget _buildResponsiveLayout(
      LayoutType layoutType,
      FilterSettings filterSettings,
      dynamic colors,
      ) {
    switch (layoutType) {
      case LayoutType.mobile:
        return _buildMobileLayout(filterSettings);
      case LayoutType.tablet:
        return _buildTabletLayout(filterSettings);
      case LayoutType.desktop:
        return _buildDesktopLayout(filterSettings);
    }
  }

  Widget _buildMobileLayout(FilterSettings filterSettings) {
    return Column(
      children: [
        ActiveFiltersBar(layoutType: LayoutType.mobile),
        DeliveryNoteSummary(
          layoutType: LayoutType.mobile,
          deliveryNotesStream: getDeliveryNotes(),
        ),
        Expanded(
          child: _buildDeliveryNotesList(filterSettings, LayoutType.mobile),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(FilterSettings filterSettings) {
    return Column(
      children: [
        ActiveFiltersBar(layoutType: LayoutType.tablet),
        DeliveryNoteSummary(
          layoutType: LayoutType.tablet,
          deliveryNotesStream: getDeliveryNotes(),
        ),
        Expanded(
          child: _buildDeliveryNotesList(filterSettings, LayoutType.tablet),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(FilterSettings filterSettings) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DesktopFilterSidebar(
          onFilterTap: () => FilterDialog.show(
            context,
            onApply: () => setState(() {}),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              DeliveryNoteSummary(
                layoutType: LayoutType.desktop,
                deliveryNotesStream: getDeliveryNotes(),
              ),
              Expanded(
                child: _buildDeliveryNotesList(filterSettings, LayoutType.desktop),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryNotesList(
      FilterSettings filterSettings,
      LayoutType layoutType,
      ) {
    final colors = Provider.of<ThemeProvider>(context).colors;

    return StreamBuilder<QuerySnapshot>(
      stream: getDeliveryNotes(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: TextStyle(color: colors.error),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colors.primary),
          );
        }

        final deliveryNotes = snapshot.data?.docs ?? [];
        final filteredNotes = _applyFilters(deliveryNotes, filterSettings);

        if (filteredNotes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getAdaptiveIcon(
                  iconName: 'receipt_long_outlined',
                  defaultIcon: Icons.receipt_long_outlined,
                  size: 64,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine Lieferscheine gefunden',
                  style: TextStyle(
                    fontSize: 18,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        switch (layoutType) {
          case LayoutType.mobile:
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredNotes.length,
              itemBuilder: (context, index) {
                final noteData =
                filteredNotes[index].data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DeliveryNoteCard(
                    noteData: noteData,
                    layoutType: layoutType,
                    isEven: index % 2 == 0,
                  ),
                );
              },
            );

          case LayoutType.tablet:
            return LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisCount = 2;
                const spacing = 16.0;
                final itemWidth = (constraints.maxWidth -
                    (spacing * (crossAxisCount - 1)) -
                    32) /
                    crossAxisCount;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: filteredNotes.map((doc) {
                      final noteData = doc.data() as Map<String, dynamic>;
                      return SizedBox(
                        width: itemWidth,
                        child: DeliveryNoteCard(
                          noteData: noteData,
                          layoutType: layoutType,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );

          case LayoutType.desktop:
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Lieferscheine (${filteredNotes.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const crossAxisCount = 3;
                        const spacing = 16.0;
                        final itemWidth = (constraints.maxWidth -
                            (spacing * (crossAxisCount - 1))) /
                            crossAxisCount;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Wrap(
                            spacing: spacing,
                            runSpacing: spacing,
                            children: filteredNotes.map((doc) {
                              final noteData =
                              doc.data() as Map<String, dynamic>;
                              return SizedBox(
                                width: itemWidth,
                                child: DeliveryNoteCard(
                                  noteData: noteData,
                                  layoutType: layoutType,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  List<QueryDocumentSnapshot> _applyFilters(
      List<QueryDocumentSnapshot> notes,
      FilterSettings filterSettings,
      ) {
    return notes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;

      // Customer filter
      if (filterSettings.activePremiumkunden.isNotEmpty ||
          filterSettings.kundenFreitextFilter.isNotEmpty) {
        final customerName = data['customerName'] as String? ?? '';

        if (filterSettings.activePremiumkunden.isNotEmpty) {
          if (!filterSettings.activePremiumkunden.contains(customerName)) {
            return false;
          }
        }

        if (filterSettings.kundenFreitextFilter.isNotEmpty) {
          if (!customerName
              .toLowerCase()
              .contains(filterSettings.kundenFreitextFilter.toLowerCase())) {
            return false;
          }
        }
      }

      // Date range filter
      if (filterSettings.dateRangeEnabled) {
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        if (createdAt != null) {
          if (filterSettings.startDate != null) {
            final startOfDay = DateTime(
              filterSettings.startDate!.year,
              filterSettings.startDate!.month,
              filterSettings.startDate!.day,
            );
            if (createdAt.isBefore(startOfDay)) return false;
          }
          if (filterSettings.endDate != null) {
            final endOfDay = DateTime(
              filterSettings.endDate!.year,
              filterSettings.endDate!.month,
              filterSettings.endDate!.day,
              23,
              59,
              59,
            );
            if (createdAt.isAfter(endOfDay)) return false;
          }
        } else {
          return false;
        }
      }

      // Volume filter
      if (filterSettings.volumeFilterEnabled) {
        final volume = (data['totalVolume'] as num?)?.toDouble() ?? 0.0;
        if (filterSettings.minVolumeEnabled &&
            volume < filterSettings.volumeRange.start) {
          return false;
        }
        if (filterSettings.maxVolumeEnabled &&
            volume > filterSettings.volumeRange.end) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}