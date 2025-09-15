import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Este archivo se genera con flutterfire configure
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'constants/app_constants.dart';
// importar la llave local
import 'core/app_scaffold.dart';

void main() async {
  // Asegurar inicialización de widgets
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error inicializando Firebase: $e');
    // La app puede seguir funcionando sin Firebase
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        fontFamily: 'Poppins', // Si tienes la fuente configurada
      ),
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      home: AuthWrapper(), // Widget que maneja el estado de autenticación
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar loading mientras se verifica el estado
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppConstants.backgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo o pájaro mientras carga
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.flutter_dash,
                      size: 60,
                      color: AppConstants.primaryBlue,
                    ),
                  ),
                  SizedBox(height: AppConstants.paddingLarge),
                  CircularProgressIndicator(
                    color: AppConstants.primaryBlue,
                  ),
                  SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'Cargando ${AppConstants.appName}...',
                    style: TextStyle(
                      color: AppConstants.textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Si hay error de conexión, mostrar WelcomeScreen
        if (snapshot.hasError) {
          print('Error en AuthWrapper: ${snapshot.error}');
          return WelcomeScreen();
        }

        // Si hay usuario autenticado, ir a HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }

        // Si no hay usuario, mostrar WelcomeScreen
        return WelcomeScreen();
      },
    );
  }
}
