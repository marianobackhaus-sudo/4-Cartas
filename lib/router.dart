import 'package:go_router/go_router.dart';

import 'screens/arena_screen.dart';
import 'screens/game_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/main_screen.dart';
import 'screens/match_result_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const MainScreen(),
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
    // Demo/visuals — single-file mock arena from teammate. Standalone, no Firebase.
    GoRoute(
      path: '/arena',
      builder: (_, _) => const ArenaScreen(),
    ),
  ],
);
