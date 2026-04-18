import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Usa native platform config (google-services.json / GoogleService-Info.plist).
  // Después de `flutterfire configure` reemplazar por:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Firebase.initializeApp();

  // Sign out any leftover anonymous session from the old auth flow.
  final user = FirebaseAuth.instance.currentUser;
  if (user != null && user.isAnonymous) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(const ProviderScope(child: App()));
}
