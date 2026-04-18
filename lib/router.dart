import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/arena_screen.dart';
import 'screens/game_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/setup_profile_screen.dart';
import 'screens/match_result_screen.dart';

class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

GoRouter createRouter() {
  final authListenable = _AuthListenable();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/setup-profile';
      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && loc == '/login') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        builder: (_, _) => const SetupProfileScreen(),
      ),
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
      GoRoute(
        path: '/arena',
        builder: (_, _) => const ArenaScreen(),
      ),
    ],
  );
}
