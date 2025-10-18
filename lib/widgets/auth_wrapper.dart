import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../providers/guest_mode_provider.dart';

/// Wrapper widget that handles authentication state and routing
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GuestModeProvider>(
      builder: (context, guestModeProvider, _) {
        // If in guest mode, show home screen without authentication
        if (guestModeProvider.isGuestMode) {
          return const HomeScreen();
        }

        // Otherwise, check Firebase authentication
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            // Show loading while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Show home screen if user is logged in
            if (snapshot.hasData && snapshot.data != null) {
              return const HomeScreen();
            }

            // Show login screen if user is not logged in
            return const LoginScreen();
          },
        );
      },
    );
  }
}
