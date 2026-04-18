import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../dev/local_mode.dart';
import '../state/auth_providers.dart';
import '../state/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _nicknameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      setState(() => _error = 'Ingresá un nickname');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = await ref.read(currentUserIdProvider.future);
      final room = await ref
          .read(roomRepositoryProvider)
          .createRoom(hostUid: uid, hostNickname: nickname);
      ref.read(nicknameProvider.notifier).state = nickname;
      if (mounted) context.go('/lobby/${room.roomCode}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Local-mode shortcut: create room as A, auto-join as B, start game, and
  /// jump directly to /game. Lets the user test the full flow on one device.
  Future<void> _hotseatStart() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(roomRepositoryProvider);
      final room = await repo.createRoom(
        hostUid: kLocalPlayerAUid,
        hostNickname: kLocalPlayerANick,
      );
      await repo.joinRoom(
        code: room.roomCode,
        uid: kLocalPlayerBUid,
        nickname: kLocalPlayerBNick,
      );
      await repo.startFirstGame(room.roomCode);
      ref.read(currentLocalUidProvider.notifier).state = kLocalPlayerAUid;
      if (mounted) context.go('/game/${room.roomCode}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRoom() async {
    final nickname = _nicknameCtrl.text.trim();
    final code = _codeCtrl.text.trim().toUpperCase();
    if (nickname.isEmpty || code.isEmpty) {
      setState(() => _error = 'Nickname y código requeridos');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final uid = await ref.read(currentUserIdProvider.future);
      await ref
          .read(roomRepositoryProvider)
          .joinRoom(code: code, uid: uid, nickname: nickname);
      ref.read(nicknameProvider.notifier).state = nickname;
      if (mounted) context.go('/lobby/$code');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgBase, AppColors.bgDeepest],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl2,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl2),
                    const Text('4 CARTAS',
                        style: AppText.hero, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xs),
                    const Text('BLITZ',
                        style: AppText.title, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.xl3),
                    TextField(
                      controller: _nicknameCtrl,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        hintText: 'Tu nombre',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    ElevatedButton(
                      onPressed: _busy ? null : _createRoom,
                      child: const Text('Crear partida'),
                    ),
                    if (kLocalMode) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _hotseatStart,
                        icon: const Icon(Icons.flash_on_rounded, size: 18),
                        label: const Text('HOTSEAT (test rápido)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.divider)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md),
                          child: Text('o', style: AppText.caption),
                        ),
                        Expanded(child: Divider(color: AppColors.divider)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.base),
                    TextField(
                      controller: _codeCtrl,
                      enabled: !_busy,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Código de sala',
                        hintText: 'A7K9Q2',
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.base),
                    OutlinedButton(
                      onPressed: _busy ? null : _joinRoom,
                      child: const Text('Unirse'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.base),
                      Text(
                        _error!,
                        style: AppText.body.copyWith(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_busy) ...[
                      const SizedBox(height: AppSpacing.base),
                      const Center(child: CircularProgressIndicator()),
                    ],
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
