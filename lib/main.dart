import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/profile.dart';
import 'screens/manager_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/scorecard_screen.dart';
import 'services/store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Connect to Firebase for cross-device sync. If it's unreachable for any
  // reason, the app still runs in local-only mode (see Store).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint('Firebase unavailable — falling back to local storage: $e');
  }
  await Store.instance.init();
  runApp(const WiggyWashApp());
}

class WiggyWashApp extends StatelessWidget {
  const WiggyWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wiggy Wash',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const _Root(),
    );
  }
}

/// Routes to onboarding / employee scorecard / manager dashboard based on the
/// saved profile, rebuilding whenever the profile changes.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Store.instance,
      builder: (context, _) {
        final profile = Store.instance.profile;
        if (profile == null || profile.name.isEmpty) {
          return const OnboardingScreen();
        }
        return switch (profile.role) {
          UserRole.manager => const ManagerScreen(),
          UserRole.employee => ScorecardScreen(profile: profile),
        };
      },
    );
  }
}
