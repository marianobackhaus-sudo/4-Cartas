import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../state/auth_providers.dart';
import '../state/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _nicknameController = TextEditingController();
  final _focusNode = FocusNode();
  bool _showNicknameError = false;
  bool _busy = false;
  String? _busyError;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() {
      if (_showNicknameError && _nicknameController.text.trim().isNotEmpty) {
        setState(() => _showNicknameError = false);
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? get _nickname {
    final v = _nicknameController.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _withBusy(Future<void> Function() op) async {
    setState(() {
      _busy = true;
      _busyError = null;
    });
    try {
      await op();
    } catch (e) {
      if (mounted) setState(() => _busyError = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onCrear() async {
    final nick = _nickname;
    if (nick == null) {
      setState(() => _showNicknameError = true);
      _focusNode.requestFocus();
      return;
    }
    await _withBusy(() async {
      final uid = await ref.read(currentUserIdProvider.future);
      final room = await ref
          .read(roomRepositoryProvider)
          .createRoom(hostUid: uid, hostNickname: nick);
      ref.read(nicknameProvider.notifier).state = nick;
      if (mounted) context.go('/lobby/${room.roomCode}');
    });
  }

  void _onUnirse() {
    final nick = _nickname;
    if (nick == null) {
      setState(() => _showNicknameError = true);
      _focusNode.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JoinSheet(
        nickname: nick,
        onJoin: (code) async {
          await _joinByCode(nick, code);
        },
      ),
    );
  }

  Future<void> _joinByCode(String nickname, String code) async {
    await _withBusy(() async {
      final uid = await ref.read(currentUserIdProvider.future);
      await ref.read(roomRepositoryProvider).joinRoom(
            code: code,
            uid: uid,
            nickname: nickname,
          );
      ref.read(nicknameProvider.notifier).state = nickname;
      if (mounted) context.go('/lobby/$code');
    });
  }

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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xl5),
                  const _CardsFan(),
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
                  _NicknameField(
                    controller: _nicknameController,
                    focusNode: _focusNode,
                    showError: _showNicknameError,
                    enabled: !_busy,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _HomeButton(
                    label: 'CREAR PARTIDA',
                    icon: Icons.add_rounded,
                    color: AppColors.primary,
                    textColor: AppColors.onPrimary,
                    solid: true,
                    onTap: _busy ? null : _onCrear,
                  ),
                  const SizedBox(height: AppSpacing.base),
                  const _OrDivider(),
                  const SizedBox(height: AppSpacing.base),
                  _HomeButton(
                    label: 'UNIRSE A PARTIDA',
                    icon: Icons.login_rounded,
                    color: AppColors.accent,
                    textColor: AppColors.accent,
                    solid: false,
                    onTap: _busy ? null : _onUnirse,
                  ),
                  if (_busy) ...[
                    const SizedBox(height: AppSpacing.base),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_busyError != null) ...[
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      _busyError!,
                      textAlign: TextAlign.center,
                      style: AppText.body.copyWith(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Join Sheet ───────────────────────────────────────────────────────────────

class _JoinSheet extends StatefulWidget {
  final String nickname;
  final Future<void> Function(String code) onJoin;
  const _JoinSheet({required this.nickname, required this.onJoin});

  @override
  State<_JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<_JoinSheet> {
  final _codeController = TextEditingController();
  bool _showCodeError = false;
  bool _busy = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onUnirme() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _showCodeError = true);
      return;
    }
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    try {
      await widget.onJoin(code);
      if (mounted) navigator.pop();
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
          Text(
            'UNIRSE A PARTIDA',
            style: AppText.title.copyWith(letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ingresá el código que te compartió tu amigo',
            style: AppText.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl2),
          _CodeField(
            controller: _codeController,
            showError: _showCodeError,
            onChanged: (_) {
              if (_showCodeError) setState(() => _showCodeError = false);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          _HomeButton(
            label: _busy ? 'UNIENDO...' : 'UNIRME',
            icon: Icons.login_rounded,
            color: AppColors.accent,
            textColor: AppColors.accent,
            solid: false,
            onTap: _busy ? null : _onUnirme,
          ),
        ],
      ),
    );
  }
}

// ─── Code Field ───────────────────────────────────────────────────────────────

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool showError;
  final ValueChanged<String> onChanged;

  const _CodeField({
    required this.controller,
    required this.showError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CÓDIGO DE SALA',
          style: AppText.label.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppText.hero.copyWith(fontSize: 28, letterSpacing: 6),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          decoration: InputDecoration(
            hintText: 'XKQZ47',
            hintStyle: AppText.hero.copyWith(
              fontSize: 28,
              letterSpacing: 6,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: AppColors.surface,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.base,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.border,
                width: showError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.accent,
                width: 2,
              ),
            ),
          ),
        ),
        if (showError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ingresá el código de la sala',
            style: AppText.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

// ─── Cards Fan ────────────────────────────────────────────────────────────────

class _CardsFan extends StatelessWidget {
  const _CardsFan();

  static const _angles = [-0.30, -0.10, 0.10, 0.30];
  static const _offsets = [
    Offset(-36, 4),
    Offset(-12, -2),
    Offset(12, -2),
    Offset(36, 4),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(4, (i) {
          return Transform.translate(
            offset: _offsets[i],
            child: Transform.rotate(
              angle: _angles[i],
              child: const _MiniCardBack(),
            ),
          );
        }),
      ),
    );
  }
}

class _MiniCardBack extends StatelessWidget {
  const _MiniCardBack();

  @override
  Widget build(BuildContext context) {
    const width = 58.0;
    const height = width / AppCardDims.aspectRatio;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBack,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
              color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.layers_rounded,
          color: AppColors.cardBackPattern.withValues(alpha: 0.45),
          size: width * 0.42,
        ),
      ),
    );
  }
}

// ─── Nickname Field ───────────────────────────────────────────────────────────

class _NicknameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showError;
  final bool enabled;

  const _NicknameField({
    required this.controller,
    required this.focusNode,
    required this.showError,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU APODO',
          style: AppText.label.copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          style: AppText.bodyStrong.copyWith(letterSpacing: 0.5),
          maxLength: 16,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'NEON_DRIFTER',
            hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceElevated,
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.md,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.border,
                width: showError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(
                color: showError ? AppColors.danger : AppColors.primary,
                width: 2,
              ),
            ),
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: showError ? AppColors.danger : AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
        if (showError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ingresá tu apodo para continuar',
            style: AppText.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}

// ─── Home Button ──────────────────────────────────────────────────────────────

class _HomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool solid;
  final VoidCallback? onTap;

  const _HomeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.solid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final bg = solid ? color : color.withValues(alpha: 0.12);
    final fg = solid ? textColor : color;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: solid ? 0.35 : 0.20),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Or Divider ───────────────────────────────────────────────────────────────

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
          child: Text(
            'O',
            style: AppText.caption.copyWith(letterSpacing: 1),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, height: 1)),
      ],
    );
  }
}
