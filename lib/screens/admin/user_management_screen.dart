import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        title: Text(
          'Benutzerverwaltung',
          style: TextStyle(color: theme.textPrimary),
        ),
        iconTheme: IconThemeData(color: theme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primary,
          unselectedLabelColor: theme.textSecondary,
          indicatorColor: theme.primary,
          tabs: const [
            Tab(text: 'Benutzer', icon: Icon(Icons.people)),
            Tab(text: 'Einladungen', icon: Icon(Icons.mail)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(theme),
          _buildInviteList(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateInviteDialog(context, theme),
        backgroundColor: theme.primary,
        child: Icon(Icons.add, color: theme.textOnPrimary),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BENUTZER LISTE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildUserList(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Keine Benutzer vorhanden',
              style: TextStyle(color: theme.textSecondary),
            ),
          );
        }

        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            final userId = users[index].id;
            return _buildUserCard(theme, user, userId);
          },
        );
      },
    );
  }

  Widget _buildUserCard(ThemeProvider theme, Map<String, dynamic> user, String userId) {
    final name = user['name'] ?? 'Unbekannt';
    final email = user['email'] ?? '';
    final userGroup = user['userGroup'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
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

          // Info
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
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // UserGroup Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getUserGroupColor(userGroup, theme).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<int>(
              value: userGroup,
              underline: const SizedBox(),
              isDense: true,
              dropdownColor: theme.surface,
              items: [
                DropdownMenuItem(value: 1, child: Text('Säger', style: TextStyle(color: theme.textPrimary))),
                DropdownMenuItem(value: 2, child: Text('Büro', style: TextStyle(color: theme.textPrimary))),
                DropdownMenuItem(value: 3, child: Text('Admin', style: TextStyle(color: theme.textPrimary))),
              ],
              onChanged: (value) {
                if (value != null) {
                  _updateUserGroup(userId, value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserGroup(String userId, int newGroup) async {
    await _db.collection('users').doc(userId).update({'userGroup': newGroup});
  }

  Color _getUserGroupColor(int group, ThemeProvider theme) {
    switch (group) {
      case 1: return theme.info;
      case 2: return theme.warning;
      case 3: return theme.error;
      default: return theme.textSecondary;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EINLADUNGEN LISTE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildInviteList(ThemeProvider theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('invites').orderBy('email').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: theme.primary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: theme.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Keine Einladungen vorhanden',
                  style: TextStyle(color: theme.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tippe auf + um eine neue Einladung zu erstellen',
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final invites = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index].data() as Map<String, dynamic>;
            final inviteId = invites[index].id;
            return _buildInviteCard(theme, invite, inviteId);
          },
        );
      },
    );
  }

  Widget _buildInviteCard(ThemeProvider theme, Map<String, dynamic> invite, String inviteId) {
    final email = invite['email'] ?? '';
    final name = invite['name'] ?? '';
    final userGroup = invite['userGroup'] ?? 1;
    final used = invite['used'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: used ? theme.success.withOpacity(0.5) : theme.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (used ? theme.success : theme.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  used ? Icons.check_circle : Icons.hourglass_empty,
                  color: used ? theme.success : theme.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isNotEmpty ? name : email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (name.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),

              // Delete Button (nur wenn nicht verwendet)
              if (!used)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: theme.error),
                  onPressed: () => _deleteInvite(inviteId),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Code & Status
          Row(
            children: [
              // Code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key, size: 14, color: theme.primary),
                    const SizedBox(width: 6),
                    Text(
                      inviteId,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // UserGroup
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getUserGroupColor(userGroup, theme).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  getUserGroupName(userGroup),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getUserGroupColor(userGroup, theme),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (used ? theme.success : theme.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  used ? 'Verwendet' : 'Offen',
                  style: TextStyle(
                    fontSize: 12,
                    color: used ? theme.success : theme.warning,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInvite(String inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = context.read<ThemeProvider>();
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Text('Einladung löschen?', style: TextStyle(color: theme.textPrimary)),
          content: Text(
            'Die Einladung "$inviteId" wird unwiderruflich gelöscht.',
            style: TextStyle(color: theme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Löschen'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _db.collection('invites').doc(inviteId).delete();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NEUE EINLADUNG ERSTELLEN
  // ═══════════════════════════════════════════════════════════════

  void _showCreateInviteDialog(BuildContext context, ThemeProvider theme) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    int selectedUserGroup = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surface,
              title: Text(
                'Neue Einladung',
                style: TextStyle(color: theme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.person, color: theme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: theme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.email, color: theme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // UserGroup
                    DropdownButtonFormField<int>(
                      value: selectedUserGroup,
                      dropdownColor: theme.surface,
                      decoration: InputDecoration(
                        labelText: 'Benutzergruppe',
                        labelStyle: TextStyle(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.group, color: theme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('Säger', style: TextStyle(color: theme.textPrimary))),
                        DropdownMenuItem(value: 2, child: Text('Büro', style: TextStyle(color: theme.textPrimary))),
                        DropdownMenuItem(value: 3, child: Text('Admin', style: TextStyle(color: theme.textPrimary))),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedUserGroup = value!);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Abbrechen', style: TextStyle(color: theme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isEmpty) return;

                    final code = _generateInviteCode();
                    await _db.collection('invites').doc(code).set({
                      'email': emailController.text.toLowerCase().trim(),
                      'name': nameController.text.trim(),
                      'userGroup': selectedUserGroup,
                      'used': false,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    _showInviteCodeDialog(context, theme, code, emailController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.textOnPrimary,
                  ),
                  child: const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[(random + i * 7) % chars.length];
    }
    return code;
  }

  void _showInviteCodeDialog(BuildContext context, ThemeProvider theme, String code, String email) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Row(
            children: [
              Icon(Icons.check_circle, color: theme.success),
              const SizedBox(width: 12),
              Text('Einladung erstellt!', style: TextStyle(color: theme.textPrimary)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Einladungscode für $email:',
                style: TextStyle(color: theme.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: theme.primary,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Teile diesen Code mit dem neuen Benutzer.',
                style: TextStyle(color: theme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: theme.textOnPrimary,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}