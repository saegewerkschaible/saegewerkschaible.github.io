// ═══════════════════════════════════════════════════════════════════════════
// lib/screens/admin/admin_screen.dart
// ═══════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/theme_provider.dart';

class AdminScreen extends StatefulWidget {
  final int initialTab;

  const AdminScreen({super.key, this.initialTab = 0});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Paketeigenschaften',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primary,
          unselectedLabelColor: theme.textSecondary,
          indicatorColor: theme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.forest), text: 'Holzarten'),
            Tab(icon: Icon(Icons.warehouse), text: 'Lagerorte'),
            Tab(icon: Icon(Icons.straighten), text: 'Maße'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildListTab(
            theme: theme,
            collection: 'wood_types',
            title: 'Holzarten',
            icon: Icons.forest,
            emptyText: 'Keine Holzarten vorhanden',
          ),
          _buildListTab(
            theme: theme,
            collection: 'locations',
            title: 'Lagerorte',
            icon: Icons.warehouse,
            emptyText: 'Keine Lagerorte vorhanden',
          ),
          _DimensionsSettingsTab(theme: theme),
        ],
      ),
    );
  }

  Widget _buildListTab({
    required ThemeProvider theme,
    required String collection,
    required String title,
    required IconData icon,
    required String emptyText,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(theme, collection, title),
              icon: const Icon(Icons.add),
              label: Text('$title hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection(collection).orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: theme.primary));
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 64, color: theme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(emptyText, style: TextStyle(color: theme.textSecondary, fontSize: 16)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: theme.border),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Unbenannt';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: theme.primary, size: 24),
                    ),
                    title: Text(name, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w500)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: theme.textSecondary),
                          onPressed: () => _showEditDialog(theme, collection, doc.id, name),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: theme.error),
                          onPressed: () => _showDeleteDialog(theme, collection, doc.id, name),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDialog(ThemeProvider theme, String collection, String title) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: theme.primary),
            const SizedBox(width: 12),
            Text('$title hinzufügen', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: theme.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _db.collection(collection).add({'name': controller.text.trim()});
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ThemeProvider theme, String collection, String docId, String currentName) {
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit, color: theme.primary),
            const SizedBox(width: 12),
            Text('Bearbeiten', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: theme.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _db.collection(collection).doc(docId).update({'name': controller.text.trim()});
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ThemeProvider theme, String collection, String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: theme.error),
            const SizedBox(width: 12),
            Text('Löschen', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: Text('Möchtest du "$name" wirklich löschen?', style: TextStyle(color: theme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection(collection).doc(docId).delete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.error, foregroundColor: Colors.white),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIMENSIONS SETTINGS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _DimensionsSettingsTab extends StatelessWidget {
  final ThemeProvider theme;
  final _db = FirebaseFirestore.instance;

  _DimensionsSettingsTab({required this.theme});

  static const _dimensions = [
    {'key': 'height', 'label': 'Stärke', 'unit': 'mm', 'icon': Icons.height},
    {'key': 'width', 'label': 'Breite', 'unit': 'mm', 'icon': Icons.swap_horiz},
    {'key': 'length', 'label': 'Länge', 'unit': 'm', 'icon': Icons.straighten},
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('settings').doc('dimensions').snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _dimensions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final dim = _dimensions[index];
            final key = dim['key'] as String;
            final label = dim['label'] as String;
            final unit = dim['unit'] as String;
            final icon = dim['icon'] as IconData;

            final values = List<double>.from(data[key] ?? []);
            values.sort();

            return _buildDimensionCard(
              context: context,
              label: label,
              unit: unit,
              icon: icon,
              values: values,
              onAdd: () => _showAddValueDialog(context, key, label, unit),
              onDelete: (value) => _deleteValue(key, values, value),
            );
          },
        );
      },
    );
  }

  Widget _buildDimensionCard({
    required BuildContext context,
    required String label,
    required String unit,
    required IconData icon,
    required List<double> values,
    required VoidCallback onAdd,
    required Function(double) onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.textPrimary),
                      ),
                      Text(
                        values.isEmpty ? 'Keine Werte' : '${values.length} Schnellauswahl-Werte',
                        style: TextStyle(fontSize: 13, color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: theme.primary),
                  onPressed: onAdd,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.border),
          if (values.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Keine Werte definiert', style: TextStyle(color: theme.textSecondary)),
            )
          else
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: values.map((value) {
                  final displayValue = value == value.toInt() ? value.toInt().toString() : value.toString();
                  return Chip(
                    label: Text('$displayValue $unit', style: TextStyle(color: theme.textPrimary)),
                    backgroundColor: theme.background,
                    deleteIcon: Icon(Icons.close, size: 18, color: theme.error),
                    onDeleted: () => onDelete(value),
                    side: BorderSide(color: theme.border),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddValueDialog(BuildContext context, String key, String label, String unit) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: theme.primary),
            const SizedBox(width: 12),
            Text('$label hinzufügen', style: TextStyle(color: theme.textPrimary)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: theme.textPrimary),
          decoration: InputDecoration(
            labelText: 'Wert in $unit',
            labelStyle: TextStyle(color: theme.textSecondary),
            suffixText: unit,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.primary, width: 2),
            ),
            filled: true,
            fillColor: theme.background,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text.replaceAll(',', '.'));
              if (value != null && value > 0) {
                await _addValue(key, value);
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: theme.primary, foregroundColor: Colors.white),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  Future<void> _addValue(String key, double value) async {
    await _db.collection('settings').doc('dimensions').set({
      key: FieldValue.arrayUnion([value]),
    }, SetOptions(merge: true));
  }

  Future<void> _deleteValue(String key, List<double> currentValues, double value) async {
    final newValues = currentValues.where((v) => v != value).toList();
    await _db.collection('settings').doc('dimensions').set({
      key: newValues,
    }, SetOptions(merge: true));
  }
}