// lib/screens/CustomerManagement/customer_management_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:saegewerk/core/theme/theme_provider.dart';
import 'package:saegewerk/customer_management/models/customer.dart';
import 'package:saegewerk/customer_management/services/customer_service.dart';
import 'package:saegewerk/services/icon_helper.dart';

import 'widgets/customer_form_bottom_sheet.dart';

import 'widgets/customer_list_tile.dart';
import 'widgets/customer_details_view.dart';

class CustomerManagementScreen extends StatefulWidget {
  final int userGroup;

  const CustomerManagementScreen({
    Key? key,
    required this.userGroup,
  }) : super(key: key);

  @override
  CustomerManagementScreenState createState() => CustomerManagementScreenState();
}

class CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String? selectedCustomerId;
  final CustomerService _customerService = CustomerService();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.surface,
        elevation: 0,
        title: Row(
          children: [
            getAdaptiveIcon(
              iconName: 'people',
              defaultIcon: Icons.people,
              color: theme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Kunden',
              style: TextStyle(color: theme.textPrimary),
            ),
          ],
        ),
        actions: [

          IconButton(
            icon: getAdaptiveIcon(
              iconName: 'person_add',
              defaultIcon: Icons.person_add,
              color: theme.primary,
            ),
            onPressed: () => CustomerFormBottomSheet.show(context),
            tooltip: 'Neuer Kunde',
          ),
        ],
      ),
      body: isDesktop
          ? _buildDesktopLayout(theme)
          : _buildMobileLayout(theme),
    );
  }

  Widget _buildDesktopLayout(dynamic theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: theme.border),
              ),
            ),
            child: Column(
              children: [
                if (selectedCustomerId == null) _buildSearchBar(theme),
                Expanded(
                  child: _buildCustomerList(theme),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: selectedCustomerId != null
              ? CustomerDetailsView(
            customerId: selectedCustomerId!,
            userGroup: widget.userGroup,
            onBack: () {
              setState(() {
                selectedCustomerId = null;
              });
            },
            isMobile: false,
          )
              : _buildEmptyState(theme),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(dynamic theme) {
    return Column(
      children: [
        if (selectedCustomerId == null) _buildSearchBar(theme),
        Expanded(
          child: selectedCustomerId == null
              ? _buildCustomerList(theme)
              : CustomerDetailsView(
            customerId: selectedCustomerId!,
            userGroup: widget.userGroup,
            onBack: () {
              setState(() {
                selectedCustomerId = null;
              });
            },
            isMobile: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(
          bottom: BorderSide(color: theme.border),
        ),
      ),
      child: TextField(
        controller: searchController,
        style: TextStyle(color: theme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Kunde suchen...',
          hintStyle: TextStyle(color: theme.primary),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: getAdaptiveIcon(
              iconName: 'search',
              defaultIcon: Icons.search,
              size: 18,
              color: theme.primary,
            ),
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: getAdaptiveIcon(
              iconName: 'clear',
              defaultIcon: Icons.clear,
              color: theme.textSecondary,
            ),
            onPressed: () {
              searchController.clear();
              setState(() {
                searchQuery = '';
              });
            },
          )
              : null,
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
        onChanged: (value) {
          setState(() {
            searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildCustomerList(dynamic theme) {
    return StreamBuilder<List<Customer>>(
      stream: _customerService.getCustomersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: theme.primary),
          );
        }

        final allCustomers = snapshot.data!;
        final customers = allCustomers.where((Customer customer) {
          final name = customer.name?.toLowerCase() ?? '';
          final city = customer.city?.toLowerCase() ?? '';
          return name.contains(searchQuery) || city.contains(searchQuery);
        }).toList();

        if (customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                getAdaptiveIcon(
                  iconName: 'person_off',
                  defaultIcon: Icons.person_off,
                  size: 48,
                  color: theme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  searchQuery.isNotEmpty
                      ? 'Keine Kunden gefunden'
                      : 'Noch keine Kunden vorhanden',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final isSelected = selectedCustomerId == customer.id;

            return CustomerListTile(
              customer: customer,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  selectedCustomerId = customer.id;
                });
              },
              onBack: () {
                setState(() {
                  selectedCustomerId = null;
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(dynamic theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          getAdaptiveIcon(
            iconName: 'person_search',
            defaultIcon: Icons.person_search,
            size: 64,
            color: theme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Wähle einen Kunden aus',
            style: TextStyle(
              fontSize: 18,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}