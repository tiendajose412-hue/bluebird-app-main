import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

import '../utils/validators.dart';
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
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

  // Control de pasos
  int _currentStep = 0; // 0: Email, 1: Código, 2: Nueva contraseña
  String _userEmail = "";
  final String _correctCode = "1234"; // Código de ejemplo

  // Timer para el código
  int _timeRemaining = 300; // 5 minutos en segundos
  bool _canResendCode = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(Duration(seconds: 1), () {
      if (mounted && _timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
        _startTimer();
      } else if (mounted) {
        setState(() {
          _canResendCode = true;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppConstants.paddingXLarge),

                // Indicador de pasos
                _buildStepIndicator(),

                SizedBox(height: AppConstants.paddingXLarge),

                // Contenido según el paso actual
                _buildStepContent(),

                SizedBox(height: AppConstants.paddingXLarge * 2),

                // Botón principal
                CustomButton(
                  text: _getButtonText(),
                  isLoading: _isLoading,
                  onPressed: _handleButtonPress,
                ),

                // Información adicional según el paso
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
      margin: EdgeInsets.only(bottom: 24),
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
        // Título con icono
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              color: AppConstants.lightBlue,
              size: 32,
            ),
          ],
        ),

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
          'Ingresa tu correo electrónico y te enviaremos un código de verificación',
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
          prefixIcon: Icon(
            Icons.email_outlined,
            color: AppConstants.subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep() {
    return Column(
      children: [
        // Título con código
        Text(
          '📱',
          style: TextStyle(fontSize: 48),
          textAlign: TextAlign.center,
        ),

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
              TextSpan(text: 'Hemos enviado un código de 4 dígitos a\n'),
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

        // Campos de código de verificación
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => _buildCodeField(index)),
        ),

        SizedBox(height: AppConstants.paddingLarge),

        // Código de ejemplo (solo para demo)
        Container(
          padding: EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: AppConstants.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            border: Border.all(color: AppConstants.lightBlue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppConstants.lightBlue,
                size: 20,
              ),
              SizedBox(width: AppConstants.paddingSmall),
              Expanded(
                child: Text(
                  'Código de ejemplo: 1234',
                  style: GoogleFonts.poppins(
                    color: AppConstants.lightBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        // Título con candado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_reset,
              color: AppConstants.lightBlue,
              size: 32,
            ),
          ],
        ),

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
          'Crea una nueva contraseña segura para tu cuenta',
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
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: AppConstants.subtitleColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: AppConstants.subtitleColor,
            ),
            onPressed: () {
              setState(() {
                _isNewPasswordVisible = !_isNewPasswordVisible;
              });
            },
          ),
        ),

        SizedBox(height: AppConstants.paddingMedium),

        // Confirmar contraseña
        CustomTextField(
          hint: AppConstants.confirmPasswordHint,
          controller: _confirmPasswordController,
          isPassword: !_isConfirmPasswordVisible,
          validator: (value) => Validators.validateConfirmPassword(
            value,
            _newPasswordController.text,
          ),
          prefixIcon: Icon(
            Icons.lock_outlined,
            color: AppConstants.subtitleColor,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility
                  : Icons.visibility_off,
              color: AppConstants.subtitleColor,
            ),
            onPressed: () {
              setState(() {
                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
              });
            },
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
            borderSide: BorderSide(color: Colors.red, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 3) {
            _codeFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _codeFocusNodes[index - 1].requestFocus();
          }

          // Auto verificar cuando se completen los 4 dígitos
          if (index == 3 && value.isNotEmpty) {
            _checkAutoCode();
          }
        },
      ),
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          _timeRemaining > 0
              ? 'Código expira en: ${_formatTime(_timeRemaining)}'
              : 'El código ha expirado',
          style: GoogleFonts.poppins(
            color: _timeRemaining > 0 ? AppConstants.subtitleColor : Colors.red,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppConstants.paddingMedium),
        TextButton(
          onPressed: _canResendCode || _timeRemaining <= 0 ? _resendCode : null,
          child: Text(
            '¿No recibiste el código?\nReenviar código',
            style: GoogleFonts.poppins(
              color: (_canResendCode || _timeRemaining <= 0)
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

  void _handleSendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
        _userEmail = _emailController.text;
        _currentStep = 1;
        _timeRemaining = 300; // Reiniciar timer
        _canResendCode = false;
      });

      _startTimer();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mark_email_read, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Código enviado a $_userEmail')),
            ],
          ),
          backgroundColor: AppConstants.primaryBlue,
        ),
      );
    }
  }

  void _handleVerifyCode() {
    String enteredCode = _codeControllers.map((c) => c.text).join();

    if (enteredCode.length != 4) {
      _showErrorDialog('Por favor ingresa los 4 dígitos del código');
      return;
    }

    if (enteredCode == _correctCode) {
      setState(() {
        _currentStep = 2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.verified_user, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Código verificado correctamente!'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showErrorDialog(
          'Código incorrecto. Intenta de nuevo.\n(Código correcto: 1234)');
      _clearCodeFields();
    }
  }

  void _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

      // Regresar a la pantalla de login después de cambiar la contraseña
      Future.delayed(Duration(seconds: 1), () {
        Navigator.popUntil(context, (route) => route.isFirst);
      });
    }
  }

  void _checkAutoCode() {
    String enteredCode = _codeControllers.map((c) => c.text).join();
    if (enteredCode.length == 4 && enteredCode == _correctCode) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) _handleVerifyCode();
      });
    }
  }

  void _resendCode() async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isLoading = false;
      _timeRemaining = 300;
      _canResendCode = false;
    });

    _clearCodeFields();
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nuevo código enviado a $_userEmail'),
        backgroundColor: AppConstants.primaryBlue,
      ),
    );
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
            Icon(Icons.error_outline, color: Colors.red, size: 24),
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

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var focusNode in _codeFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }
}
