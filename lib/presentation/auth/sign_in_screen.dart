import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/motion.dart';
import '../../data/api/social_auth.dart';
import '../providers/auth_providers.dart';

/// Combined sign-in / sign-up screen with email/password + Google/Apple.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _social = SocialAuth();
  bool _isRegister = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted && ref.read(isSignedInProvider)) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = ref.read(authControllerProvider.notifier);
    await _run(() async {
      if (_isRegister) {
        await ctrl.register(_email.text.trim(), _password.text,
            displayName: _name.text.trim().isEmpty ? null : _name.text.trim());
      } else {
        await ctrl.login(_email.text.trim(), _password.text);
      }
      final state = ref.read(authControllerProvider);
      if (state.hasError) throw state.error!;
    });
  }

  Future<void> _google() => _run(() async {
        final token = await _social.googleIdToken();
        if (token == null) return;
        await ref.read(authControllerProvider.notifier).oauth('google', token);
        final s = ref.read(authControllerProvider);
        if (s.hasError) throw s.error!;
      });

  Future<void> _apple() => _run(() async {
        final token = await _social.appleIdentityToken();
        if (token == null) return;
        await ref.read(authControllerProvider.notifier).oauth('apple', token);
        final s = ref.read(authControllerProvider);
        if (s.hasError) throw s.error!;
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 20),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/brand/paceshift_mark.svg',
                    width: 72,
                    height: 72,
                  ),
                ),
              ),
              Text(
                _isRegister ? 'Join PaceShift' : 'Welcome back',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Sync your plan across devices and back it up safely.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              if (_isRegister)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextFormField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                        labelText: 'Name (optional)',
                        prefixIcon: Icon(Icons.person_outline)),
                  ),
                ),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => (v == null || v.length < 8)
                    ? 'At least 8 characters'
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isRegister ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() => _isRegister = !_isRegister),
                child: Text(_isRegister
                    ? 'Have an account? Sign in'
                    : 'New here? Create an account'),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or', style: theme.textTheme.bodySmall),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _busy ? null : _google,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _busy ? null : _apple,
                icon: const Icon(Icons.apple_rounded),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 16),
              Text(
                'You can keep using PaceShift without an account — signing in '
                'just adds cloud backup and multi-device sync.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ].revealStagger(context),
          ),
        ),
      ),
    );
  }
}

/// Opens the sign-in screen (used from Settings).
Future<void> showSignIn(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
    );
