import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
});
  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _verifyOTP() async {
    String otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP code...')),
      );
      return;
    }

    setState(() => _isLoading= true);

    bool verified= await _authService.verifyOTP(
      verificationId: widget.verificationId,
      otp: otp,
    );
    
    setState(() => _isLoading = false);

    if (!mounted) return;
    
    if (verified) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
        title: const Text(
          'Verify Phone',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 20,
          ),
        ),
        elevation: 2,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.verified_user,
              size: 80,
              color: Color(0xFF0D47A1),
            ),

            const SizedBox(height: 24),

            const Text(
              'Verify your phone number',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
                letterSpacing: 1.0,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Enter the 6-digit code sent to ${widget.phoneNumber}',
              textAlign: TextAlign.justify,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blueAccent,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Color(0xFF0D47A1),
              ),
              decoration: InputDecoration(
                hintText: '------',
                counterText: '',
                border:  OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF0D47A1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white30,
                ),
              ),
            const SizedBox(height: 32),

            _isLoading
                ? const CircularProgressIndicator(
                    color: Color(0xFF0D47A1),
                    strokeWidth: 3
            )
                : ElevatedButton(
                    onPressed: _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 55),
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white30,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

            const SizedBox(height: 24),

            GestureDetector(
              onTap: () { },
              child: const Text(
                'Resend Code',
                style: TextStyle(
                  color: Color(0xFF42A5F5),
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}