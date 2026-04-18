import 'package:go_router/go_router.dart';

import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/match_result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/lobby/:code',
      builder: (_, state) =>
          LobbyScreen(roomCode: state.pathParameters['code']!),
    ),
    GoRoute(
      path: '/game/:code',
      builder: (_, state) =>
          GameScreen(roomCode: state.pathParameters['code']!),
    ),
    GoRoute(
      path: '/result/:code',
      builder: (_, state) =>
          MatchResultScreen(roomCode: state.pathParameters['code']!),
    ),
  ],
);
