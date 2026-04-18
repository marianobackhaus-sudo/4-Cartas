import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../state/auth_providers.dart';
import '../state/providers.dart';

const _kAppVersion = 'v1.0.0';

void _showSignOutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger, size: 36),
            const SizedBox(height: AppSpacing.base),
            Text(
              '¿Cerrar sesión?',
              style: AppText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '¿Estás seguro que querés cerrar sesión?',
              style: AppText.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          'CANCELAR',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await ref.read(authRepositoryProvider).signOut();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.danger, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          'SALIR',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = ref.watch(currentUserProvider).valueOrNull?.displayName ?? '—';
    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'MI PERFIL',
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xl2),
                const Center(child: _AvatarCircle()),
                const SizedBox(height: AppSpacing.base),
                Text(
                  username,
                  style: AppText.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl2),
                _MenuGroup(
                  items: [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Mi perfil',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _EditProfileSheet(),
                      ),
                    ),
                    _MenuItem(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Mis compras',
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _MisComprasSheet(),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _SignOutButton(onTap: () => _showSignOutDialog(context, ref)),
                const SizedBox(height: AppSpacing.base),
                Text(
                  _kAppVersion,
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar Circle ────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// ─── Menu Group ───────────────────────────────────────────────────────────────

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.border, indent: 52),
          ],
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppText.bodyStrong)),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sign Out Button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.danger, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'CERRAR SESIÓN',
              style: TextStyle(
                color: AppColors.danger,
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

// ─── Mis Compras Sheet ────────────────────────────────────────────────────────

class _MisComprasSheet extends StatelessWidget {
  const _MisComprasSheet();

  static const _ownedPacks = [
    _OwnedPack(
      name: 'CARTAS SCALONETA',
      description: 'Con la celeste y blanca. Campeones del mundo.',
      cardColor: Color(0xFF0A2A4A),
      accentColor: Color(0xFF75AADB),
      borderColor: Color(0xFFFFFFFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.xl + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('MIS COMPRAS', style: AppText.title.copyWith(letterSpacing: 1)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${_ownedPacks.length} paquete${_ownedPacks.length == 1 ? '' : 's'} comprado${_ownedPacks.length == 1 ? '' : 's'}',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xl),
          ..._ownedPacks.map((pack) => _OwnedPackRow(pack: pack)),
        ],
      ),
    );
  }
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet();

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _usernameController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.displayName ?? '',
  );
  final _passwordController = TextEditingController();
  bool _busy = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Ingresá un nombre de usuario';
    if (v.trim().length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return null; // opcional
    if (v.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final newName = _usernameController.text.trim();
      final newPass = _passwordController.text;
      if (newName != (user.displayName ?? '')) {
        await user.updateDisplayName(newName);
      }
      if (newPass.isNotEmpty) {
        await user.updatePassword(newPass);
        _passwordController.clear();
      }
      if (mounted) {
        setState(() => _successMessage = 'Cambios guardados');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.code == 'requires-recent-login'
          ? 'Cerrá sesión y volvé a ingresar para cambiar la contraseña'
          : e.message ?? 'Error al guardar');
    } catch (_) {
      setState(() => _errorMessage = 'Algo salió mal, intentá de nuevo');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.base,
        AppSpacing.md,
        AppSpacing.base,
        AppSpacing.xl + bottomPadding,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('MI PERFIL', style: AppText.title.copyWith(letterSpacing: 1)),
              const SizedBox(height: AppSpacing.xl2),
              // Avatar
              Center(
                child: GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Foto de perfil — próximamente', style: AppText.body),
                      backgroundColor: AppColors.surface,
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 44),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.surfaceElevated, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: AppColors.onPrimary, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              // Username
              Text('NOMBRE DE USUARIO', style: AppText.label.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _usernameController,
                enabled: !_busy,
                style: AppText.bodyStrong,
                maxLength: 20,
                textCapitalization: TextCapitalization.characters,
                validator: _validateUsername,
                decoration: _fieldDecoration(
                  hint: 'NEON_DRIFTER',
                  icon: Icons.person_outline_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.base),
              // Password
              Text('NUEVA CONTRASEÑA', style: AppText.label.copyWith(letterSpacing: 1.5)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Dejá vacío si no querés cambiarla',
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _passwordController,
                enabled: !_busy,
                obscureText: _obscurePassword,
                style: AppText.bodyStrong,
                validator: _validatePassword,
                decoration: _fieldDecoration(
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textMuted, size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              // Feedback
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.base),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                  ),
                  child: Text(_errorMessage!, style: AppText.caption.copyWith(color: AppColors.danger), textAlign: TextAlign.center),
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: AppSpacing.base),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                  ),
                  child: Text(_successMessage!, style: AppText.caption.copyWith(color: AppColors.success), textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              _busy
                  ? const Center(child: CircularProgressIndicator())
                  : GestureDetector(
                      onTap: _save,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              blurRadius: 18, offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'GUARDAR CAMBIOS',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      counterText: '',
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base, vertical: AppSpacing.md,
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
    );
  }
}

class _OwnedPack {
  final String name;
  final String description;
  final Color cardColor;
  final Color accentColor;
  final Color borderColor;

  const _OwnedPack({
    required this.name,
    required this.description,
    required this.cardColor,
    required this.accentColor,
    required this.borderColor,
  });
}

class _OwnedPackRow extends StatelessWidget {
  final _OwnedPack pack;
  const _OwnedPackRow({required this.pack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40 / (2.5 / 3.5),
              decoration: BoxDecoration(
                color: pack.cardColor,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: pack.borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: pack.accentColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.layers_rounded,
                  color: pack.accentColor.withValues(alpha: 0.7),
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.name, style: AppText.bodyStrong),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    pack.description,
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.success),
              ),
              child: Text(
                'EQUIPADO',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
