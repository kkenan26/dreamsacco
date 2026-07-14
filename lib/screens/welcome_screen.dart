import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'DreamSacco',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
              'Smart group savings for private and public communities',
              textAlign: TextAlign.center,
                style: TextStyle(fontSize:18,
                color: Color(0xFF42A5F5),
                fontStyle: FontStyle.italic,
            ),
          ),
              const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16, fontWeight:FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      foregroundColor: const Color(0xFF0D47A1),
                      side: const BorderSide(color: Color(0xFF0D47A1), width: 2),
                      shape: RoundedSuperellipseBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
      );
    }
  }