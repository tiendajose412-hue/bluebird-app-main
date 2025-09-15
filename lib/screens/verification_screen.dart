// lib/screens/verification_screen.dart (mejorada con countdown + cooldown + auto-pegar)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../services/firebase_auth_service.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String email;
  final String phone;
  const VerificationScreen({
    super.key,
    required this.email,
    required this.phone,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final FirebaseAuthService _svc = FirebaseAuthService();
  final List<TextEditingController> _controllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());

  bool _isLoading = false;
  bool _resending = false;

  // Timers
  Timer? _expireTimer;
  Timer? _resendTimer;
  int _expireSeconds = 600; // 10 min
  int _resendSeconds = 0; // cooldown de reenviar

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _controllers.every((c) => c.text.length == 1);

  @override
  void initState() {
    super.initState();
    _startExpireTimer();
  }

  @override
  void dispose() {
    _expireTimer?.cancel();
    _resendTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startExpireTimer() {
    _expireTimer?.cancel();
    _expireSeconds = 600;
    _expireTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_expireSeconds <= 0) {
        t.cancel();
        setState(() {}); // deshabilita botón
        return;
      }
      setState(() => _expireSeconds--);
    });
  }

  void _startResendCooldown([int seconds = 60]) {
    _resendTimer?.cancel();
    _resendSeconds = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendSeconds <= 0) {
        t.cancel();
        setState(() {});
        return;
      }
      setState(() => _resendSeconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppConstants.paddingXLarge),
              Text(
                AppConstants.verificationCode,
                style: TextStyle(
                  color: AppConstants.textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Ingresa el código de 4 dígitos que enviamos a:\n${widget.email}',
                style: TextStyle(
                  color: AppConstants.subtitleColor,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppConstants.paddingXLarge * 2),

              // Inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(4, (i) => _buildCodeField(i)),
              ),

              SizedBox(height: AppConstants.paddingMedium),

              // Expira en...
              Text(
                _expireSeconds > 0
                    ? 'El código expira en ${(_expireSeconds ~/ 60).toString().padLeft(2, '0')}:${(_expireSeconds % 60).toString().padLeft(2, '0')}'
                    : 'El código venció. Reenviar para recibir uno nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _expireSeconds > 0
                      ? AppConstants.subtitleColor
                      : Colors.redAccent,
                ),
              ),

              SizedBox(height: AppConstants.paddingXLarge),

              // Verificar
              CustomButton(
                text: "Usar código",
                isLoading: _isLoading,
                onPressed: _handleVerification, // <- no metas condicional aquí
              ),

              SizedBox(height: AppConstants.paddingMedium),

              // Reenviar
              TextButton(
                onPressed:
                    (_resending || _resendSeconds > 0) ? null : _handleResend,
                child: _resending
                    ? const CircularProgressIndicator()
                    : Text(
                        _resendSeconds > 0
                            ? 'Reenviar en ${_resendSeconds}s'
                            : 'No me llegó el código\nReenviar',
                        style: TextStyle(
                          color: AppConstants.lightBlue,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 50,
      height: 60,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          color: AppConstants.textColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppConstants.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            borderSide: BorderSide(color: AppConstants.primaryBlue, width: 2),
          ),
        ),
        onChanged: (value) {
          // Si el usuario pegó todo el código (p. ej. "1234")
          if (value.length > 1) {
            final digits = value.replaceAll(RegExp(r'\D'), '');
            for (int i = 0; i < 4; i++) {
              _controllers[i].text = i < digits.length ? digits[i] : '';
            }
            setState(() {});
            _focusNodes[3].requestFocus();
            if (_complete) _handleVerification();
            return;
          }

          // navegación normal
          if (value.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }

          if (_complete) _handleVerification();
        },
      ),
    );
  }

  Future<void> _handleVerification() async {
    if (_code.length != 4 || _code.contains(RegExp(r'\D'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa los 4 dígitos')),
      );
      return;
    }
    if (_expireSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El código venció. Reenvía uno nuevo.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final ok = await _svc.verifyEmailCode(
        email: widget.email,
        code: _code,
      );
      if (ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Verificación exitosa!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo verificar el correo')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _resending = true);
    try {
      final r = await _svc.resendEmailOtp(widget.email);
      // reiniciar expiración y cooldown local si fue exitoso
      if (r['success'] == true) {
        _startExpireTimer();
        _startResendCooldown(60);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r['message'] ?? 'Código reenviado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }
}
