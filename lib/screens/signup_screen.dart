import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'otp_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void _signUp() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please  fill in all fields :) ')),
      );
      return;
    }

    setState(() => _isLoading= true);

    String? uid = await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        phone: '+256$phone',
    );

    if (uid== null) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed. Email may already be in use :/')),
      );
      return;
    }

    await _authService.sendOTP(
      phoneNumber: '+256$phone',
      onCodeSent: (verificationId) {
        setState(() => _isLoading= false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              verificationId: verificationId,
              phoneNumber: '+256$phone',
            ),
          ),
        );
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color (0xFFF0F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor:Colors.white,
        title: const Text('Create account'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            const Text(
              'Welcome To DreamSACCO...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Create your account here ^_^',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF42A5F5),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email Address',
              prefixIcon: const Icon(Icons.email, color: Color(0xFF0D47A1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock, color: Color(0xFFD047A1)),
              suffixIcon:IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFD047A1),
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),


          _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
            :ElevatedButton(
              onPressed: _signUp,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 55),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Create account and verify Phone number',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ',
                style: TextStyle(color: Colors.grey)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Text(
                  'Log In',
                  style: TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }
}