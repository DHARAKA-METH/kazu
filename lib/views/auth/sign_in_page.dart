import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:kazu/app.dart';
import 'auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SignInScreen(
              providers: providers,
              actions: [
                // This runs for BOTH sign-in and registration
                AuthStateChangeAction<SignedIn>((context, state) async {
                  final user = state.user;
                  if (user != null) {
                    setState(() => _isLoading = true);

                    // Save user to Firestore
                    bool success = await AuthService.saveUserToFirestore(user);

                    setState(() => _isLoading = false);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Welcome! You are signed in.')),
                      );

                      // Navigate to MainApp
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MainApp()),
                        );
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save user data. Please try again.'),
                        ),
                      );
                    }
                  }
                }),
              ],
              headerBuilder: (context, constraints, _) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'Welcome',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
