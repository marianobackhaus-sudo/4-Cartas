import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';
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
    final uidAsync = ref.watch(currentUserIdProvider);
    final roomAsync = ref.watch(roomStreamProvider(roomCode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sala'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
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
                  child: Text('Sala no encontrada',
                      style: AppText.title),
                );
              }
              // Auto-navigate to game once started.
              if (room.status == RoomStatus.playing) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) context.go('/game/$roomCode');
                });
              }
              return _LobbyBody(room: room, myUid: uidAsync.asData?.value);
            },
          ),
        ),
      ),
    );
  }
}

class _LobbyBody extends ConsumerWidget {
  const _LobbyBody({required this.room, required this.myUid});

  final RoomDoc room;
  final String? myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHost = myUid != null && myUid == room.hostId;
    final bothIn = room.seatOrder.length == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('CÓDIGO DE SALA',
              style: AppText.label, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: room.roomCode));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Código copiado')),
                );
              }
            },
            child: AnimatedContainer(
              duration: AppDurations.fast,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              alignment: Alignment.center,
              child: Text(room.roomCode, style: AppText.hero),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('Tocá para copiar',
              style: AppText.caption, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl2),
          _PlayerSlot(
            seat: 0,
            uid: room.seatOrder.isNotEmpty ? room.seatOrder[0] : null,
            players: room.players,
            isMe: myUid != null &&
                room.seatOrder.isNotEmpty &&
                room.seatOrder[0] == myUid,
          ),
          const SizedBox(height: AppSpacing.md),
          _PlayerSlot(
            seat: 1,
            uid: room.seatOrder.length > 1 ? room.seatOrder[1] : null,
            players: room.players,
            isMe: myUid != null &&
                room.seatOrder.length > 1 &&
                room.seatOrder[1] == myUid,
          ),
          const Spacer(),
          if (isHost)
            ElevatedButton(
              onPressed: bothIn
                  ? () =>
                      ref.read(gameControllerProvider(room.roomCode)).startMatch()
                  : null,
              child: Text(bothIn ? 'Iniciar partida' : 'Esperando rival...'),
            )
          else
            Text(
              bothIn
                  ? 'Esperando que el anfitrión inicie...'
                  : 'Esperando un segundo jugador...',
              style: AppText.caption,
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _PlayerSlot extends StatelessWidget {
  const _PlayerSlot({
    required this.seat,
    required this.uid,
    required this.players,
    required this.isMe,
  });

  final int seat;
  final String? uid;
  final Map<String, PlayerInfo> players;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final info = uid == null ? null : players[uid];
    final filled = info != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isMe ? AppColors.accent : AppColors.border,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: filled
                ? AppColors.primary.withValues(alpha: 0.15)
                : AppColors.border,
            child: Text(
              filled ? (info.nickname.characters.first.toUpperCase()) : '?',
              style: AppText.titleSmall
                  .copyWith(color: filled ? AppColors.primary : AppColors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filled ? info.nickname : 'Esperando jugador...',
                  style: AppText.bodyStrong,
                ),
                Text('Asiento ${seat + 1}', style: AppText.caption),
              ],
            ),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('VOS',
                  style: AppText.caption
                      .copyWith(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
