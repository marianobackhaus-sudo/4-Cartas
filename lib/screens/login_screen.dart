import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../state/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
    final valid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim());
    if (!valid) return 'Email no válido';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Ingresá tu contraseña';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (_isRegister) {
        await repo.registerWithEmail(email, password);
        if (mounted) context.go('/setup-profile');
      } else {
        await repo.signInWithEmail(email, password);
        if (mounted) context.go('/');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Algo salió mal, intentá de nuevo');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendlyError(String code) => switch (code) {
        'user-not-found' => 'No existe una cuenta con ese email',
        'wrong-password' => 'Contraseña incorrecta',
        'invalid-credential' => 'Email o contraseña incorrectos',
        'email-already-in-use' => 'Ese email ya está registrado',
        'weak-password' => 'Contraseña muy débil',
        'invalid-email' => 'Email no válido',
        'too-many-requests' => 'Demasiados intentos, esperá un momento',
        _ => 'Error: $code',
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.bgDeepest,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.bgBase, AppColors.bgDeepest],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl5),
                    const _CardsFanSmall(),
                    const SizedBox(height: AppSpacing.xl2),
                    const Text(
                      '4 CARTAS',
                      style: AppText.hero,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'B L I T Z',
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(
                        letterSpacing: 8,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl5),
                    Text(
                      _isRegister ? 'CREAR CUENTA' : 'INICIAR SESIÓN',
                      style: AppText.title.copyWith(letterSpacing: 2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl2),
                    _AuthField(
                      controller: _emailController,
                      label: 'EMAIL',
                      hint: 'tucorreo@ejemplo.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      enabled: !_busy,
                    ),
                    const SizedBox(height: AppSpacing.base),
                    _AuthField(
                      controller: _passwordController,
                      label: 'CONTRASEÑA',
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      enabled: !_busy,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.base),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppText.caption.copyWith(
                            color: AppColors.danger,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    _busy
                        ? const Center(child: CircularProgressIndicator())
                        : _AuthButton(
                            label: _isRegister
                                ? 'CREAR CUENTA'
                                : 'INICIAR SESIÓN',
                            onTap: _submit,
                          ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegister
                              ? '¿Ya tenés cuenta?  '
                              : '¿No tenés cuenta?  ',
                          style: AppText.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: _busy
                              ? null
                              : () => setState(() {
                                    _isRegister = !_isRegister;
                                    _errorMessage = null;
                                    _formKey.currentState?.reset();
                                  }),
                          child: Text(
                            _isRegister ? 'Iniciá sesión' : 'Registrate',
                            style: AppText.bodyStrong.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Auth Field ───────────────────────────────────────────────────────────────

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final Widget? suffixIcon;

  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          style: AppText.bodyStrong,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
            errorStyle: AppText.caption.copyWith(color: AppColors.danger),
          ),
        ),
      ],
    );
  }
}

// ─── Auth Button ──────────────────────────────────────────────────────────────

class _AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AuthButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cards Fan (small) ────────────────────────────────────────────────────────

class _CardsFanSmall extends StatelessWidget {
  const _CardsFanSmall();

  static const _angles = [-0.20, -0.07, 0.07, 0.20];
  static const _offsets = [
    Offset(-28, 3),
    Offset(-9, -1),
    Offset(9, -1),
    Offset(28, 3),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(4, (i) {
          return Transform.translate(
            offset: _offsets[i],
            child: Transform.rotate(
              angle: _angles[i],
              child: Container(
                width: 46,
                height: 46 / AppCardDims.aspectRatio,
                decoration: BoxDecoration(
                  color: AppColors.cardBack,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.layers_rounded,
                    color: AppColors.cardBackPattern.withValues(alpha: 0.45),
                    size: 18,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
