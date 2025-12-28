import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

import '../../core/theme/theme_provider.dart';
import '../../services/auth_service.dart';
import '../home/start_screen.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _inviteController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _inviteFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _inviteFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _inviteController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _inviteFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = await _authService.registerWithInviteCode(
        email: _emailController.text,
        password: _passwordController.text,
        inviteCode: _inviteController.text,
      );

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, StartScreen.id);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ModalProgressHUD(
        inAsyncCall: _isLoading,
        progressIndicator: CircularProgressIndicator(color: theme.primary),
        child: Scaffold(
          backgroundColor: theme.background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      _buildLogo(theme, size),
                      const SizedBox(height: 32),

                      // Titel
                      Text(
                        'Konto erstellen',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form
                      _buildForm(theme),
                      const SizedBox(height: 24),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bereits ein Konto? ',
                            style: TextStyle(color: theme.textSecondary),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              LoginScreen.id,
                            ),
                            child: Text(
                              'Anmelden',
                              style: TextStyle(
                                color: theme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeProvider theme, Size size) {
    return Container(
      height: size.height * 0.15,
      padding: const EdgeInsets.all(16),
      child: Image.asset(
        theme.isDarkMode ? 'assets/images/logo_w.png' : 'assets/images/logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback wenn Logo nicht vorhanden
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SCHAIBLE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: theme.textPrimary,
                  letterSpacing: 2,
                ),
              ),
              Container(
                width: 60,
                height: 3,
                color: theme.primary,
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _buildForm(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Info Box
            Container(
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
                      'Du benötigst einen Einladungscode vom Administrator.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Einladungscode
            TextFormField(
              controller: _inviteController,
              focusNode: _inviteFocus,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: theme.textPrimary),
              decoration: _inputDecoration(
                theme: theme,
                hint: 'Einladungscode',
                icon: Icons.vpn_key_outlined,
                hasFocus: _inviteFocus.hasFocus,
              ),
              validator: (v) => v!.isEmpty ? 'Bitte Code eingeben' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: theme.textPrimary),
              decoration: _inputDecoration(
                theme: theme,
                hint: 'Email',
                icon: Icons.email_outlined,
                hasFocus: _emailFocus.hasFocus,
              ),
              validator: (v) => v!.isEmpty ? 'Bitte Email eingeben' : null,
            ),
            const SizedBox(height: 16),

            // Passwort
            TextFormField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              obscureText: _obscurePassword,
              style: TextStyle(color: theme.textPrimary),
              decoration: _inputDecoration(
                theme: theme,
                hint: 'Passwort',
                icon: Icons.lock_outline,
                hasFocus: _passwordFocus.hasFocus,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: theme.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) => v!.length < 6 ? 'Mind. 6 Zeichen' : null,
            ),

            // Error
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error,
                  style: TextStyle(color: theme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Register Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Registrieren',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ThemeProvider theme,
    required String hint,
    required IconData icon,
    required bool hasFocus,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textSecondary),
      prefixIcon: Icon(
        icon,
        color: hasFocus ? theme.primary : theme.textSecondary,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: hasFocus ? theme.surface : theme.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.error),
      ),
    );
  }
}