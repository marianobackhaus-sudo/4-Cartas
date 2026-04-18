import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';

class EditarPerfilScreen extends ConsumerStatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  ConsumerState<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends ConsumerState<EditarPerfilScreen> {
  final _usernameController = TextEditingController(text: 'NEON_DRIFTER');
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _currentPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  void _onSave() {
    // TODO: guardar cambios con Firebase Auth
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cambios guardados',
          style: AppText.label.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.bgDeepest,
        appBar: AppBar(
          backgroundColor: AppColors.bgDeepest,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
            onPressed: () => context.go('/perfil'),
          ),
          title: const Text(
            'EDITAR PERFIL',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          centerTitle: true,
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl2),
                  // Foto de perfil
                  Center(child: _EditableAvatar(onTap: _onPickPhoto)),
                  const SizedBox(height: AppSpacing.xl2),
                  // Divider con label
                  _SectionLabel(label: 'INFORMACIÓN DE CUENTA'),
                  const SizedBox(height: AppSpacing.md),
                  // Nombre de usuario
                  _EditField(
                    label: 'NOMBRE DE USUARIO',
                    controller: _usernameController,
                    icon: Icons.person_outline_rounded,
                    maxLength: 16,
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionLabel(label: 'CAMBIAR CONTRASEÑA'),
                  const SizedBox(height: AppSpacing.md),
                  // Contraseña actual
                  _EditField(
                    label: 'CONTRASEÑA ACTUAL',
                    controller: _currentPassController,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscureCurrent,
                    onToggleObscure: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Nueva contraseña
                  _EditField(
                    label: 'NUEVA CONTRASEÑA',
                    controller: _newPassController,
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscureNew,
                    onToggleObscure: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  // Guardar
                  _SaveButton(onTap: _onSave),
                  const SizedBox(height: AppSpacing.xl2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPickPhoto() {
    // TODO: abrir image picker
  }
}

// ─── Editable Avatar ──────────────────────────────────────────────────────────

class _EditableAvatar extends StatelessWidget {
  final VoidCallback onTap;
  const _EditableAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.textMuted,
              size: 52,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.bgDeepest, width: 2),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.onPrimary,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppText.label.copyWith(letterSpacing: 1.5),
    );
  }
}

// ─── Edit Field ───────────────────────────────────────────────────────────────

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.onToggleObscure,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.label.copyWith(letterSpacing: 1.2)),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: AppText.bodyStrong.copyWith(letterSpacing: 0.5),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceElevated,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

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
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: AppColors.onPrimary, size: 18),
            SizedBox(width: AppSpacing.sm),
            Text(
              'GUARDAR CAMBIOS',
              style: TextStyle(
                color: AppColors.onPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
