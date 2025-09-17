import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../utils/validators.dart';

import '../services/firebase_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Servicios
  final _svc = FirebaseAuthService();

  // Controladores
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _codeControllers =
      List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _codeFocusNodes =
      List.generate(4, (index) => FocusNode());

  final _formKey = GlobalKey<FormState>();

  // Estados
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _resending = false;

  // Control de pasos
  int _currentStep = 0; // 0: Email, 1: Código, 2: Nueva contraseña
  String _userEmail = "";

  // Timers
  static const int _otpExpireSecondsTotal = 600; // 10 min (backend)
  static const int _resendCooldownSecondsTotal = 60; // cooldown backend
  int _expireSeconds = _otpExpireSecondsTotal;
  int _resendCooldownSeconds = 0;
  Timer? _expireTimer;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _codeControllers) c.dispose();
    for (var f in _codeFocusNodes) f.dispose();
    _expireTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ============================
  // Timers
  // ============================
  void _startExpireTimer() {
    _expireTimer?.cancel();
    _expireSeconds = _otpExpireSecondsTotal;
    _expireTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_expireSeconds > 0) {
        setState(() {
          _expireSeconds--;
        });
      } else {
        t.cancel();
        setState(() {});
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _resendCooldownSeconds = _resendCooldownSecondsTotal;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendCooldownSeconds > 0) {
        setState(() {
          _resendCooldownSeconds--;
        });
      } else {
        t.cancel();
        setState(() {});
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ============================
  // UI
  // ============================
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppConstants.paddingXLarge),
                _buildStepIndicator(),
                SizedBox(height: AppConstants.paddingXLarge),
                _buildStepContent(),
                SizedBox(height: AppConstants.paddingXLarge * 2),

                // Botón principal
                CustomButton(
                  text: _getButtonText(),
                  isLoading: _isLoading,
                  onPressed: _handleButtonPress,
                ),

                // “Reenviar” y contador solo en paso 1 (código)
                if (_currentStep == 1) ...[
                  SizedBox(height: AppConstants.paddingLarge),
                  _buildResendSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStepDot(0, "Email"),
        _buildStepLine(0),
        _buildStepDot(1, "Código"),
        _buildStepLine(1),
        _buildStepDot(2, "Nueva Contraseña"),
      ],
    );
  }

  Widget _buildStepDot(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  isActive ? AppConstants.primaryBlue : AppConstants.cardColor,
              border: Border.all(
                color: isCurrent
                    ? AppConstants.lightBlue
                    : isActive
                        ? AppConstants.primaryBlue
                        : AppConstants.subtitleColor,
                width: 2,
              ),
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: GoogleFonts.poppins(
                        color: isActive
                            ? Colors.white
                            : AppConstants.subtitleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: isCurrent
                  ? AppConstants.lightBlue
                  : isActive
                      ? AppConstants.textColor
                      : AppConstants.subtitleColor,
              fontSize: 10,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = _currentStep > step;
    return Container(
      height: 2,
      width: 32,
      color: isActive
          ? AppConstants.primaryBlue
          : AppConstants.subtitleColor.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 24),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildCodeStep();
      case 2:
        return _buildPasswordStep();
      default:
        return _buildEmailStep();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.email_outlined, color: AppConstants.lightBlue, size: 32),
        ]),
        SizedBox(height: AppConstants.paddingMedium),
        Text(
          '¿Olvidaste tu contraseña?',
          style: GoogleFonts.poppins(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingMedium),
        Text(
          'Ingresa tu correo y te enviaremos un código de verificación.',
          style: GoogleFonts.poppins(
            color: AppConstants.subtitleColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingXLarge),
        CustomTextField(
          hint: AppConstants.emailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateEmail,
          prefixIcon:
              Icon(Icons.email_outlined, color: AppConstants.subtitleColor),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        const Text('📱',
            style: TextStyle(fontSize: 48), textAlign: TextAlign.center),
        SizedBox(height: AppConstants.paddingMedium),
        Text(
          'Código de Verificación',
          style: GoogleFonts.poppins(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingMedium),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: AppConstants.subtitleColor,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: 'Hemos enviado un código de 4 dígitos a\n'),
              TextSpan(
                text: _userEmail,
                style: GoogleFonts.poppins(
                  color: AppConstants.lightBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppConstants.paddingXLarge),

        // 4 dígitos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildCodeField(index)),
        ),
        SizedBox(height: AppConstants.paddingLarge),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_reset, color: AppConstants.lightBlue, size: 32),
        ]),
        SizedBox(height: AppConstants.paddingMedium),
        Text(
          'Nueva Contraseña',
          style: GoogleFonts.poppins(
            color: AppConstants.textColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingMedium),
        Text(
          'Crea una nueva contraseña segura para tu cuenta.',
          style: GoogleFonts.poppins(
            color: AppConstants.subtitleColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingXLarge),
        // Nueva contraseña
        CustomTextField(
          hint: AppConstants.newPasswordHint,
          controller: _newPasswordController,
          isPassword: !_isNewPasswordVisible,
          validator: Validators.validatePassword,
          prefixIcon:
              Icon(Icons.lock_outlined, color: AppConstants.subtitleColor),
          suffixIcon: IconButton(
            icon: Icon(
              _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: AppConstants.subtitleColor,
            ),
            onPressed: () =>
                setState(() => _isNewPasswordVisible = !_isNewPasswordVisible),
          ),
        ),
        SizedBox(height: AppConstants.paddingMedium),
        // Confirmar
        CustomTextField(
          hint: AppConstants.confirmPasswordHint,
          controller: _confirmPasswordController,
          isPassword: !_isConfirmPasswordVisible,
          validator: (v) => Validators.validateConfirmPassword(
              v, _newPasswordController.text),
          prefixIcon:
              Icon(Icons.lock_outlined, color: AppConstants.subtitleColor),
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: AppConstants.subtitleColor,
            ),
            onPressed: () => setState(
                () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField(int index) {
    return SizedBox(
      width: 60,
      height: 70,
      child: TextFormField(
        controller: _codeControllers[index],
        focusNode: _codeFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: GoogleFonts.poppins(
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _codeFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _codeFocusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }

  Widget _buildResendSection() {
    final canResend = _resendCooldownSeconds == 0;
    return Column(
      children: [
        Text(
          _expireSeconds > 0
              ? 'Código expira en: ${_formatTime(_expireSeconds)}'
              : 'El código ha expirado',
          style: GoogleFonts.poppins(
            color: _expireSeconds > 0 ? AppConstants.subtitleColor : Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingMedium),
        TextButton(
          onPressed: (_expireSeconds <= 0 || canResend) && !_resending
              ? _resendCode
              : null,
          child: _resending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  canResend
                      ? '¿No recibiste el código?\nReenviar código'
                      : 'Espera ${_formatTime(_resendCooldownSeconds)} para reenviar',
                  style: GoogleFonts.poppins(
                    color: canResend
                        ? AppConstants.lightBlue
                        : AppConstants.subtitleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ],
    );
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return "Enviar Código";
      case 1:
        return "Verificar Código";
      case 2:
        return "Cambiar Contraseña";
      default:
        return "Continuar";
    }
  }

  // ============================
  // Handlers
  // ============================
  void _handleButtonPress() {
    switch (_currentStep) {
      case 0:
        _handleSendCode();
        break;
      case 1:
        _handleVerifyCode();
        break;
      case 2:
        _handleChangePassword();
        break;
    }
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim().toLowerCase();
    setState(() => _isLoading = true);

    final r = await _svc.requestPasswordResetOtp(email);
    setState(() => _isLoading = false);

    if (r['success'] == true) {
      setState(() {
        _userEmail = email;
        _currentStep = 1;
        _clearCodeFields();
        _startExpireTimer(); // 10 min
        _startCooldownTimer(); // 60 s cooldown
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Código enviado a $_userEmail')),
            ],
          ),
          backgroundColor: AppConstants.primaryBlue,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                r['message']?.toString() ?? 'No se pudo enviar el código')),
      );
    }
  }

  void _handleVerifyCode() {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length != 4 || code.contains(RegExp(r'\D'))) {
      _showErrorDialog('Por favor ingresa los 4 dígitos del código');
      return;
    }
    if (_expireSeconds <= 0) {
      _showErrorDialog('El código expiró. Reenvíalo.');
      return;
    }
    // Si todo ok, pasamos a nueva contraseña
    setState(() => _currentStep = 2);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.verified_user, color: Colors.white),
            SizedBox(width: 8),
            Text('¡Código ingresado! Ingresa tu nueva contraseña.'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeControllers.map((c) => c.text).join();
    final p1 = _newPasswordController.text.trim();
    final p2 = _confirmPasswordController.text.trim();

    if (code.length != 4 || code.contains(RegExp(r'\D'))) {
      _showErrorDialog('Código inválido.');
      return;
    }
    if (p1.length < 6) {
      _showErrorDialog('La contraseña debe tener al menos 6 caracteres');
      return;
    }
    if (p1 != p2) {
      _showErrorDialog('Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);
    final r = await _svc.resetPasswordWithOtp(
      email: _userEmail,
      code: code,
      newPassword: p1,
    );
    setState(() => _isLoading = false);

    if (r['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Contraseña cambiada exitosamente!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
      // Volver a login
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    } else {
      _showErrorDialog(
          r['message']?.toString() ?? 'No se pudo cambiar la contraseña');
    }
  }

  Future<void> _resendCode() async {
    if (_resending) return;
    setState(() => _resending = true);
    final r = await _svc.requestPasswordResetOtp(_userEmail);
    setState(() => _resending = false);

    if (r['success'] == true) {
      _clearCodeFields();
      _startExpireTimer(); // reinicia 10 min
      _startCooldownTimer(); // reinicia 60 s
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nuevo código enviado a $_userEmail'),
          backgroundColor: AppConstants.primaryBlue,
        ),
      );
    } else {
      _showErrorDialog(
          r['message']?.toString() ?? 'No se pudo reenviar el código');
    }
  }

  void _clearCodeFields() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _codeFocusNodes[0].requestFocus();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 24),
            SizedBox(width: AppConstants.paddingSmall),
            Text(
              'Error',
              style: GoogleFonts.poppins(
                color: AppConstants.textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: AppConstants.subtitleColor),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryBlue,
            ),
            child: Text(
              'Entendido',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
