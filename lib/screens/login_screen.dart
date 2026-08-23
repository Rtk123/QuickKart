import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isSignup = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      children: [
                        const TextSpan(text: 'Quick', style: TextStyle(color: AppTheme.brand)),
                        TextSpan(text: 'Kart', style: TextStyle(color: scheme.onSurface)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isSignup) ...[
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(labelText: t.fullName),
                      validator: (v) =>
                          (v == null || v.trim().length < 2) ? t.enterName : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: t.email),
                    validator: (v) =>
                        (v == null || !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v))
                            ? t.invalidEmail
                            : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(labelText: t.password),
                    validator: (v) =>
                        (v == null || v.length < 6) ? t.passwordTooShort : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: TextStyle(color: scheme.error, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isSignup ? t.createAccount : t.login),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => setState(() {
                      _isSignup = !_isSignup;
                      _error = null;
                    }),
                    child: Text(
                      _isSignup ? t.alreadyHaveAccount : t.createNewAccount,
                      style: const TextStyle(color: AppTheme.brand),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final t = context.read<SettingsService>().t;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isSignup) {
        final loggedInImmediately = await AuthService.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          fullName: _nameCtrl.text.trim(),
        );
        // Agar session mil gaya to AuthGate khud Home par le jaayega.
        // Warna user ko batana zaroori hai ki pehle email confirm karna hai —
        // warna login "Email not confirmed" se fail hoga.
        if (mounted && !loggedInImmediately) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(t.confirmEmailSent),
              duration: const Duration(seconds: 6),
            ),
          );
          setState(() => _isSignup = false);
        }
      } else {
        await AuthService.signIn(
            email: _emailCtrl.text.trim(), password: _passCtrl.text.trim());
        // StreamBuilder (main.dart) auth state change dekh kar khud navigate kar dega
      }
    } catch (e) {
      setState(() => _error = AuthService.describeError(e, t));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
