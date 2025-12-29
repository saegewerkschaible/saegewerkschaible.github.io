// lib/screens/delivery_notes/dialogs/customer_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/theme/theme_provider.dart';
import '../services/cart_provider.dart';

class CustomerSelectionDialog extends StatefulWidget {
  const CustomerSelectionDialog({super.key});

  @override
  State<CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<CustomerSelectionDialog> {
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final cart = context.watch<CartProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.people, color: theme.primary),
                ),
                const SizedBox(width: 16),
                Text(
                  'Kunde',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const Spacer(),
                // Kein Kunde Button
                TextButton.icon(
                  onPressed: () {
                    cart.clearCustomer();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.person_off, size: 18, color: theme.textSecondary),
                  label: Text('Kein Kunde', style: TextStyle(color: theme.textSecondary)),
                  style: TextButton.styleFrom(
                    backgroundColor: theme.background,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: theme.textSecondary),
                ),
              ],
            ),
          ),

          // Suchfeld
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kunde suchen...',
                hintStyle: TextStyle(color: theme.textSecondary),
                prefixIcon: Icon(Icons.search, color: theme.textSecondary),
                filled: true,
                fillColor: theme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.primary, width: 2),
                ),
              ),
              onChanged: (value) => setState(() => _searchTerm = value.toLowerCase()),
            ),
          ),

          const SizedBox(height: 16),

          // Kundenliste
          Expanded(
            child: _buildCustomerList(theme, cart),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(ThemeProvider theme, CartProvider cart) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Fehler: ${snapshot.error}', style: TextStyle(color: theme.error)),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Filtern nach Suchbegriff
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final city = (data['city'] ?? '').toString().toLowerCase();
          return name.contains(_searchTerm) || city.contains(_searchTerm);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_search, size: 48, color: theme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Keine Kunden gefunden',
                  style: TextStyle(color: theme.textSecondary),
                ),
              ],
            ),
          );
        }

        // Nach Anfangsbuchstaben gruppieren
        final Map<String, List<DocumentSnapshot>> grouped = {};
        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final name = data['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            final letter = name[0].toUpperCase();
            grouped.putIfAbsent(letter, () => []);
            grouped[letter]!.add(doc);
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final letter = grouped.keys.elementAt(index);
            final customers = grouped[letter]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index > 0) const SizedBox(height: 16),

                // Buchstaben-Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Kundenkarten
                ...customers.map((doc) => _buildCustomerCard(doc, theme, cart)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCustomerCard(DocumentSnapshot doc, ThemeProvider theme, CartProvider cart) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString() ?? '';
    final city = data['city']?.toString() ?? '';
    final zipCode = data['zipCode']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          cart.setCustomer(data);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                backgroundColor: theme.primary.withOpacity(0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Name + Adresse
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (city.isNotEmpty || zipCode.isNotEmpty)
                      Text(
                        '$zipCode $city'.trim(),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: theme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}