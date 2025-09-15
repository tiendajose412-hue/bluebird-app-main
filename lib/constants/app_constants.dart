import 'package:flutter/material.dart';

class AppConstants {
  // Colores principales de la aplicación
  static const Color primaryBlue = Color(0xFF4461F2);      // Azul principal
  static const Color darkBlue = Color(0xFF1E293B);         // Azul oscuro
  static const Color lightBlue = Color(0xFF60A5FA);        // Azul claro
  static const Color backgroundColor = Color(0xFF0F172A);   // Fondo oscuro
  static const Color cardColor = Color(0xFF1E293B);        // Color de tarjetas
  static const Color textColorblue = Color(0xFF4461F2);     // Texto azul
  static const Color textColor = Colors.white;             // Texto blanco
  static const Color subtitleColor = Color(0xFF94A3B8);    // Texto secundario
  
  // Espaciados estándar
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Radios de borde
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  
  // Textos de la aplicación
  static const String appName = "Bluebird Soft";
  static const String welcomeTitle = "Bienvenido a Bluebird Soft";
  static const String loginButton = "Ingresar";
  static const String registerButton = "Registrarse";
  static const String emailHint = "Ingresa tu correo electrónico";
  static const String phoneHint = "Número de teléfono"; // ✨ NUEVO
  static const String passwordHint = "Contraseña";
  static const String newPasswordHint = "Ingresa tu nueva contraseña";
  static const String confirmPasswordHint = "Confirmar contraseña";
  static const String forgotPassword = "¿Desea recuperar contraseña?";
  static const String noAccount = "¿No tienes una cuenta?";
  static const String registerHere = "Regístrese aquí!";
  static const String continueWith = "o continúa con";
  static const String changePassword = "Cambiar contraseña";
  static const String verificationCode = "Código verificación";
  static const String createAccount = "Crear cuenta";
}