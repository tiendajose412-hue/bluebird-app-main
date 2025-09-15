import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/bird_widget.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Fondo con degradado azul
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 3, 74, 120), //
              Color.fromARGB(8, 26, 47, 1), //
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppConstants.paddingLarge,
              vertical: AppConstants.paddingMedium,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Espaciador superior
                Spacer(flex: 2),

                // Pájaro principal
                Center(
                  child: BirdWidget(
                    width: screenWidth * 0.75, //
                    height: screenWidth * 0.75, //
                    showShadow: true,
                    shadowBlur: 20.0,
                    shadowColor: Colors.black.withOpacity(0.015),
                  ),
                ),

                // Espaciador entre pájaro y botones
                Spacer(flex: 3),

                // Contenedor con botones
                Row(
                  children: [
                    // Botón Ingresar - Azul relleno
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppConstants.loginButton,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold, // Poppins Bold
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16), // Espacio entre botones

                    // Botón Registrarse - Blanco/Outlined
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            AppConstants.registerButton,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Espaciador inferior
                Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
