/*import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';
import '../constants/app_constants.dart';
import 'home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String phone;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _auth = FirebaseAuthService();
  bool _checking = false;
  bool _resending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica tu correo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Te enviamos un correo a:',
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Revisa tu bandeja de entrada o spam y toca el enlace para verificar tu cuenta.',
                style: TextStyle(
                  color: AppConstants.subtitleColor,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _checking ? null : _checkVerified,
                child: _checking
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Ya verifiqué'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _resending ? null : _resend,
                child: _resending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Reenviar correo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    final ok = await _auth.refreshAndSyncEmailVerified();
    setState(() => _checking = false);

    if (!mounted) return;

    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userEmail: widget.email,
            userPhone: widget.phone,
          ),
        ),
        (_) => false,
      );
    } else {
      _snack('Aún no está verificado. Intenta de nuevo en unos segundos.');
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    final r = await _auth.resendEmailVerification();
    setState(() => _resending = false);

    if (!mounted) return;
    _snack(r['message'] ?? 'Listo');
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }
}
/*