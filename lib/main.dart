import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/sign_in_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // run `flutterfire configure` first
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true); // offline cache
  runApp(const StudyNetworkApp());
}

class StudyNetworkApp extends StatelessWidget {
  const StudyNetworkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Network',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3F51B5),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF3F51B5),
      ),
      home: const AuthGate(),
    );
  }
}

/// Routes: signed out -> sign in; no profile -> onboarding; else role shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = authSnap.data;
        if (user == null) return const SignInScreen();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const _Loading();
            if (!snap.data!.exists) return OnboardingScreen(user: user);
            return HomeShell(appUser: AppUser.fromDoc(snap.data!));
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
