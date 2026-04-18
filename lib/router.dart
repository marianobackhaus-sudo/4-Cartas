import 'package:go_router/go_router.dart';

import 'screens/arena_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/match_result_screen.dart';
import 'screens/editar_perfil_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/tienda_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/perfil',
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
    // Demo/visuals — single-file mock arena from teammate. Standalone, no Firebase.
    GoRoute(
      path: '/arena',
      builder: (_, _) => const ArenaScreen(),
    ),
    GoRoute(
      path: '/tienda',
      builder: (_, _) => const TiendaScreen(),
    ),
    GoRoute(
      path: '/perfil',
      builder: (_, _) => const PerfilScreen(),
    ),
    GoRoute(
      path: '/perfil/editar',
      builder: (_, _) => const EditarPerfilScreen(),
    ),
  ],
);
