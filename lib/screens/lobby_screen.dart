import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../data/room_doc.dart';
import '../state/auth_providers.dart';
import '../state/game_controller.dart';
import '../state/room_providers.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key, required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(roomCode));
    final myUid = ref.watch(currentUserIdProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textSecondary),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          '4 CARTAS BLITZ',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
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
          child: roomAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Error: $e',
                  style: AppText.body.copyWith(color: AppColors.danger),
                ),
              ),
            ),
            data: (room) {
              if (room == null) {
                return const Center(
                    child:
                        Text('Sala no encontrada', style: AppText.title));
              }
              if (room.status == RoomStatus.playing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/game/$roomCode');
                });
              }
              return _Body(room: room, myUid: myUid);
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.room, required this.myUid});

  final RoomDoc room;
  final String? myUid;

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: room.roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Código copiado',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = myUid != null && myUid == room.hostId;
    final bothIn = room.seatOrder.length == 2;
    final myInfo = myUid == null ? null : room.players[myUid];
    final opponentUid = room.seatOrder.where((u) => u != myUid).isEmpty
        ? null
        : room.seatOrder.firstWhere((u) => u != myUid);
    final opponentInfo =
        opponentUid == null ? null : room.players[opponentUid];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl2),
          _PlayerCard(
            nickname: myInfo?.nickname ?? 'TÚ',
            subtitle: 'TÚ${isHost ? ' · ANFITRIÓN' : ' · INVITADO'}',
            statusColor: AppColors.success,
            avatarIcon: Icons.person_rounded,
          ),
          const SizedBox(height: AppSpacing.base),
          if (opponentInfo != null)
            _PlayerCard(
              nickname: opponentInfo.nickname,
              subtitle: isHost ? 'INVITADO' : 'ANFITRIÓN',
              statusColor: AppColors.accent,
              avatarIcon: Icons.person_outline_rounded,
            )
          else
            const _EmptySeatCard(),
          const SizedBox(height: AppSpacing.xl2),
          _CodeSection(
            roomCode: room.roomCode,
            onCopy: () => _copyCode(context),
          ),
          const SizedBox(height: AppSpacing.xl2),
          _StatusCard(bothIn: bothIn, isHost: isHost),
          const Spacer(),
          if (isHost)
            _LobbyButton(
              label: bothIn ? 'INICIAR PARTIDA' : 'ESPERANDO RIVAL...',
              icon: bothIn
                  ? Icons.play_arrow_rounded
                  : Icons.hourglass_empty_rounded,
              color: AppColors.primary,
              textColor: AppColors.onPrimary,
              onTap: bothIn
                  ? () => ref
                      .read(gameControllerProvider(room.roomCode))
                      .startMatch()
                  : null,
            )
          else
            const _GuestWaitingNote(),
          const SizedBox(height: AppSpacing.xl2),
        ],
      ),
    );
  }
}

// ─── Player Card ──────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final String nickname;
  final String subtitle;
  final Color statusColor;
  final IconData avatarIcon;

  const _PlayerCard({
    required this.nickname,
    required this.subtitle,
    required this.statusColor,
    required this.avatarIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child:
                Icon(avatarIcon, color: AppColors.textMuted, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nickname.toUpperCase(), style: AppText.titleSmall),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      subtitle,
                      style: AppText.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySeatCard extends StatelessWidget {
  const _EmptySeatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgDeepest,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: AppColors.textMuted, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ASIENTO LIBRE',
                  style: AppText.titleSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 3),
              Text('ESPERANDO...',
                  style: AppText.caption.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 1.2,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Code Section ─────────────────────────────────────────────────────────────

class _CodeSection extends StatelessWidget {
  final String roomCode;
  final VoidCallback onCopy;
  const _CodeSection({required this.roomCode, required this.onCopy});

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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                roomCode,
                style: AppText.hero.copyWith(letterSpacing: 10),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.base),
              GestureDetector(
                onTap: onCopy,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy_rounded,
                          color: AppColors.textSecondary, size: 14),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'COPIAR CÓDIGO',
                        style: AppText.caption.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Status Card ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final bool bothIn;
  final bool isHost;
  const _StatusCard({required this.bothIn, required this.isHost});

  @override
  Widget build(BuildContext context) {
    final (color, label) = bothIn
        ? (AppColors.success, 'LISTO PARA JUGAR')
        : (AppColors.warning, 'ESPERANDO AMIGO...');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppText.label.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Guest Waiting Note ───────────────────────────────────────────────────────

class _GuestWaitingNote extends StatelessWidget {
  const _GuestWaitingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'ESPERANDO AL ANFITRIÓN...',
            style: AppText.label.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lobby Button ─────────────────────────────────────────────────────────────

class _LobbyButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _LobbyButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
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
