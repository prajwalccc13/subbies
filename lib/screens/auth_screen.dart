// =============================================================================
// screens/auth_screen.dart — SIGN IN OR CREATE AN ACCOUNT
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:subbies/state/auth_controller.dart';
import 'package:subbies/widgets/field_label.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isCreatingAccount = false; // Which mode are we in?
  bool _isBusy = false; // Waiting for Firebase?
  bool _obscurePassword = true; // Password shown as dots?
  String? _error; // Message to show, if any

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });

    final auth = context.read<AuthController>();
    final navigator = Navigator.of(context);
    final email = _emailController.text;
    final password = _passwordController.text;

    final error = _isCreatingAccount
        ? await auth.createAccount(email, password)
        : await auth.signIn(email, password);

    if (!mounted) return;
    if (error == null) {
      navigator.pop(); // Success: back to Settings
    } else {
      setState(() {
        _isBusy = false;
        _error = error;
      });
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error =
          'Type your email above, then tap "Forgot password?" again.');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<AuthController>().sendPasswordReset(email);

    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('Password reset email sent to $email.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreatingAccount ? 'Create account' : 'Sign in'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // AutofillGroup tells the phone "these fields belong together", so
          // password managers can fill in the email AND password at once.
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  _isCreatingAccount
                      ? 'Back up your subscriptions and use Subbies on all '
                          'your devices.'
                      : 'Welcome back. Your subscriptions will sync to this '
                          'device.',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                const FieldLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress, // Shows the @ key
                  autocorrect: false,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'you@example.com'),
                  validator: (value) =>
                      (value == null || !value.contains('@'))
                          ? 'Enter your email address'
                          : null,
                ),
                const SizedBox(height: 20),

                const FieldLabel('Password'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Dots instead of letters
                  // "newPassword" tells password managers to SUGGEST a
                  // strong password; "password" tells them to FILL one in.
                  autofillHints: [
                    _isCreatingAccount
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  textInputAction: TextInputAction.done,
                  // Pressing "done" on the keyboard submits the form.
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: _isCreatingAccount ? 'At least 6 characters' : null,
                    // An eye button inside the field to show/hide the password.
                    suffixIcon: IconButton(
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Use at least 6 characters'
                      : null,
                ),

                if (!_isCreatingAccount)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isBusy ? null : _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.error),
                    ),
                  ),
                const SizedBox(height: 24),

                // onPressed: null DISABLES a button. While busy, it shows a
                // small spinner instead of text, and can't be tapped twice.
                FilledButton(
                  onPressed: _isBusy ? null : _submit,
                  child: _isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(_isCreatingAccount ? 'Create account' : 'Sign in'),
                ),
                const SizedBox(height: 12),

                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => setState(() {
                            _isCreatingAccount = !_isCreatingAccount;
                            _error = null;
                          }),
                  child: Text(
                    _isCreatingAccount
                        ? 'Already have an account? Sign in'
                        : 'New here? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}