// lib/screens/CustomerManagement/widgets/customer_list_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/services/icon_helper.dart';

class CustomerListTile extends StatelessWidget {
  final Customer customer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onBack;

  const CustomerListTile({
    Key? key,
    required this.customer,
    required this.isSelected,
    required this.onTap,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isMobile = MediaQuery.of(context).size.width <= 800;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? theme.primaryLight : theme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primary : theme.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: _buildAvatar(theme),
        title: Text(
          customer.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (customer.city != null)
              Text(
                customer.city!,
                style: TextStyle(color: theme.textSecondary),
              ),
            if (customer.fullStreet != null)
              Text(
                customer.fullStreet!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.primary,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected && isMobile)
              IconButton(
                icon: getAdaptiveIcon(
                  iconName: 'arrow_back',
                  defaultIcon: Icons.arrow_back,
                  color: theme.textPrimary,
                ),
                onPressed: onBack,
              )
            else
              getAdaptiveIcon(
                iconName: 'chevron_right',
                defaultIcon: Icons.chevron_right,
                color: theme.textSecondary,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAvatar(ThemeProvider theme) {
    // Wenn Logo vorhanden, zeige Logo
    if (customer.logoColorUrl != null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.network(
            customer.logoColorUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildLetterAvatar(),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.primary,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // Fallback: Buchstabe
    return _buildLetterAvatar();
  }

  Widget _buildLetterAvatar() {
    return CircleAvatar(
      backgroundColor: customer.color,
      child: Text(
        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}