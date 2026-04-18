import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../data/room_doc.dart';
import '../state/auth_providers.dart';
import '../state/providers.dart';
import '../state/room_providers.dart';

class MatchResultScreen extends ConsumerWidget {
  const MatchResultScreen({super.key, required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomStreamProvider(roomCode));
    final myUid = ref.watch(currentUserIdProvider).asData?.value;

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
          child: roomAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e', style: AppText.body)),
            data: (room) {
              if (room == null || myUid == null || room.game == null) {
                return const Center(child: CircularProgressIndicator());
              }
              return _Content(room: room, myUid: myUid);
            },
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.room, required this.myUid});

  final RoomDoc room;
  final String myUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = room.game!;
    final winnerUid = game.matchWinnerUid;
    final iWon = winnerUid == myUid;
    final oppUid = game.opponentOf(myUid);
    final winnerName = winnerUid == null
        ? '—'
        : room.players[winnerUid]?.nickname ?? winnerUid;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            iWon
                ? Icons.emoji_events_rounded
                : Icons.sentiment_dissatisfied_rounded,
            size: 96,
            color: iWon ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.base),
          Text(iWon ? 'GANASTE' : 'PERDISTE',
              style: AppText.hero
                  .copyWith(color: iWon ? AppColors.primary : AppColors.textPrimary),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text('Campeón: $winnerName',
              style: AppText.title, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl2),
          _ScoreCard(
            nickname: room.players[myUid]?.nickname ?? myUid,
            gamesWon: game.gamesWon[myUid] ?? 0,
            isMe: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreCard(
            nickname: room.players[oppUid]?.nickname ?? oppUid,
            gamesWon: game.gamesWon[oppUid] ?? 0,
            isMe: false,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              // Only host deletes the room; guests just navigate out.
              if (room.hostId == myUid) {
                await ref
                    .read(roomRepositoryProvider)
                    .delete(room.roomCode)
                    .catchError((_) {});
              }
              if (context.mounted) context.go('/');
            },
            child: const Text('Volver al inicio'),
          ),
        ],
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.nickname,
    required this.gamesWon,
    required this.isMe,
  });

  final String nickname;
  final int gamesWon;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Text(nickname, style: AppText.bodyStrong),
          ),
          Text('$gamesWon', style: AppText.scoreNumeric),
          const SizedBox(width: AppSpacing.xs),
          Text('partidas', style: AppText.caption),
        ],
      ),
    );
  }
}
