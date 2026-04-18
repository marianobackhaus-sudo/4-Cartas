import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'dev/local_mode.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kLocalMode) {
    // Uses native platform config (google-services.json / GoogleService-Info.plist).
    // After running `flutterfire configure`, replace with:
    //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase init failed: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: kLocalMode ? buildLocalOverrides() : const [],
      child: const App(),
    ),
  );
}
