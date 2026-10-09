import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:svenska/core/services/auth_service.dart';
import 'package:svenska/core/utils/routes_name.dart';
import 'package:svenska/features/main/presentation/pages/desktop_view_page.dart';
import 'package:svenska/injection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorText;
  Timer? _blockTimer;

  AuthService get _auth => sl<AuthService>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _usernameFocus.requestFocus();
    });
    _scheduleBlockTick();
  }

  @override
  void dispose() {
    _blockTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _scheduleBlockTick() {
    _blockTimer?.cancel();
    if (!_auth.attemptGate.isBlocked) return;
    _blockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_auth.attemptGate.isBlocked) {
        _blockTimer?.cancel();
        setState(() => _errorText = null);
      } else {
        setState(() {});
      }
    });
  }

  String? _blockMessage() {
    if (!_auth.attemptGate.isBlocked) return null;
    final secs = _auth.attemptGate.remainingBlock?.inSeconds ?? 0;
    return 'Too many attempts. Try again in ${secs}s';
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_auth.attemptGate.isBlocked) {
      setState(() => _errorText = _blockMessage());
      _scheduleBlockTick();
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    final result = _auth.tryLogin(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    switch (result.kind) {
      case AuthLoginResultKind.success:
        context.go(AppRoutes.workstationMain);
        return;
      case AuthLoginResultKind.wrongCredentials:
        _passwordController.clear();
        setState(() {
          _submitting = false;
          _errorText = 'Wrong username or password';
        });
        _passwordFocus.requestFocus();
        return;
      case AuthLoginResultKind.blocked:
        _passwordController.clear();
        setState(() {
          _submitting = false;
          _errorText = _blockMessage();
        });
        _scheduleBlockTick();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockMsg = _blockMessage();
    final showError = blockMsg ?? _errorText;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.04),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF00FFFF).withOpacity(0.2),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/icons/scanner_icon.png',
                                width: 64,
                                height: 64,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'SVENSKA AUTOMOTIVE — INDUSTRIAL WORKSTATION',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            focusNode: _usernameFocus,
                            controller: _usernameController,
                            enabled: !_auth.attemptGate.isBlocked && !_submitting,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _passwordFocus.requestFocus(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _fieldDecoration('Username'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            focusNode: _passwordFocus,
                            controller: _passwordController,
                            enabled: !_auth.attemptGate.isBlocked && !_submitting,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _fieldDecoration('Password').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          if (showError != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              showError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFF87171), fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_auth.attemptGate.isBlocked || _submitting) ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kAccent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: kAccent.withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('LOGIN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF00FFFF), width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
