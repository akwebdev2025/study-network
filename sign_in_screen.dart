import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      _error = 'Sign-in failed. Check your connection and try again.';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.school_rounded, size: 72, color: t.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Study Network',
                  textAlign: TextAlign.center, style: t.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text('Your complete academic companion',
                  textAlign: TextAlign.center, style: t.textTheme.bodyLarge),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _busy ? null : _signIn,
                icon: _busy
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.login),
                label: const Text('Continue with Google'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center,
                    style: TextStyle(color: t.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
