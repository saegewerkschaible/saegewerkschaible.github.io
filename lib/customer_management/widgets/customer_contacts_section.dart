// lib/screens/CustomerManagement/widgets/customer_contacts_section.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/services/icon_helper.dart';


import '../dialogs/contact_person_dialog.dart';
import '../dialogs/delete_contact_dialog.dart';

class CustomerContactsSection extends StatelessWidget {
  final String customerId;

  const CustomerContactsSection({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance

          .collection('customers')
          .doc(customerId)
          .collection('contacts')
          .orderBy('isPrimary', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final contacts = snapshot.data?.docs ?? [];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'contacts',
                    defaultIcon: Icons.contacts,
                    color: theme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ansprechpartner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: getAdaptiveIcon(
                      iconName: 'person_add',
                      defaultIcon: Icons.person_add,
                      color: theme.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ContactPersonDialog(
                          customerId: customerId,
                        ),
                      );
                    },
                    tooltip: 'Ansprechpartner hinzufügen',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (contacts.isEmpty)
                Text(
                  'Keine Ansprechpartner vorhanden',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                ...contacts.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildContactCard(context, theme, doc.id, data);
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactCard(
      BuildContext context,
      dynamic theme,
      String contactId,
      Map<String, dynamic> data,
      ) {
    final isPrimary = data['isPrimary'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.border),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPrimary
              ? theme.primaryLight
              : theme.background,
          child: getAdaptiveIcon(
            iconName: 'person',
            defaultIcon: Icons.person,
            color: isPrimary ? theme.primary : theme.textSecondary,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                data['name'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HAUPT',
                  style: TextStyle(
                    color: theme.textOnPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data['position'] != null &&
                data['position'].toString().isNotEmpty)
              Text(
                data['position'],
                style: TextStyle(color: theme.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            if (data['phone'] != null &&
                data['phone'].toString().isNotEmpty)
              Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'phone',
                    defaultIcon: Icons.phone,
                    size: 12,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      data['phone'],
                      style: TextStyle(color: theme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (data['email'] != null &&
                data['email'].toString().isNotEmpty)
              Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'email',
                    defaultIcon: Icons.email,
                    size: 12,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      data['email'],
                      style: TextStyle(color: theme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: getAdaptiveIcon(
            iconName: 'more_vert',
            defaultIcon: Icons.more_vert,
            color: theme.textSecondary,
          ),
          color: theme.surface,
          onSelected: (value) {
            if (value == 'edit') {
              showDialog(
                context: context,
                builder: (context) => ContactPersonDialog(
                  customerId: customerId,
                  contactId: contactId,
                  contactData: data,
                ),
              );
            } else if (value == 'delete') {
              DeleteContactDialog.show(
                context,
                customerId: customerId,
                contactId: contactId,
                contactName: data['name'] ?? '',
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'edit',
                    defaultIcon: Icons.edit,
                    size: 20,
                    color: theme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bearbeiten',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  getAdaptiveIcon(
                    iconName: 'delete',
                    defaultIcon: Icons.delete,
                    size: 20,
                    color: theme.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Löschen',
                    style: TextStyle(color: theme.error),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}