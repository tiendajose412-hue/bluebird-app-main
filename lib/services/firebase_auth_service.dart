// lib/services/firebase_auth_service.dart (OTP por correo de 4 dígitos, versión mejorada)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
      region: 'us-central1'); // <- región correcta

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---- Helper: traducir errores de Cloud Functions a mensajes amigables
  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Debes iniciar sesión para continuar.';
      case 'invalid-argument':
        return 'Datos inválidos. Revisa el email/código.';
      case 'permission-denied':
        return 'El email no coincide con tu cuenta.';
      case 'resource-exhausted':
        return 'Espera 60 segundos antes de reenviar.';
      case 'deadline-exceeded':
        return 'El código expiró. Pide uno nuevo.';
      case 'failed-precondition':
        return 'No hay un código activo. Solicita uno primero.';
      default:
        return e.message ?? 'Error inesperado (Functions).';
    }
  }

  // ==============================
  // REGISTRO (OTP por correo)
  // ==============================
  Future<Map<String, dynamic>> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = result.user!;
      final normalizedEmail = email.trim().toLowerCase();

      // Guardar datos adicionales en Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': normalizedEmail,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      }, SetOptions(merge: true));

      // Solicitar OTP por correo (Cloud Function)
      try {
        final callable = _functions.httpsCallable('requestEmailOtp');
        await callable.call({'email': normalizedEmail});
      } on FirebaseFunctionsException catch (e) {
        // Si falló el envío inicial, opcionalmente borra el usuario para no dejar cuentas "a medias"
        try {
          await _firestore.collection('users').doc(user.uid).delete();
        } catch (_) {}
        try {
          await user.delete();
        } catch (_) {}
        return {'success': false, 'message': _mapFunctionsError(e)};
      }

      return {
        'success': true,
        'user': user,
        'message': 'Usuario registrado. Te enviamos un código de verificación.'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar usuario';
      switch (e.code) {
        case 'weak-password':
          message = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          message = 'El email ya está registrado';
          break;
        case 'invalid-email':
          message = 'Email inválido';
          break;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // ==============================
  // LOGIN (bloquea si no verificó)
  // ==============================
  Future<Map<String, dynamic>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Refresca el estado para leer emailVerified actual
      await result.user?.reload();
      final fresh = _auth.currentUser;

      if (fresh != null && !fresh.emailVerified) {
        // Si no está verificado, no permitimos sesión
        await _auth.signOut();
        return {
          'success': false,
          'message':
              'Tu correo no está verificado. Ingresa el código enviado a tu email.'
        };
      }

      // Si está verificado, reflejarlo en Firestore (merge)
      if (fresh != null && fresh.emailVerified) {
        await _firestore
            .collection('users')
            .doc(fresh.uid)
            .set({'emailVerified': true}, SetOptions(merge: true));
      }

      return {
        'success': true,
        'user': fresh,
        'message': 'Inicio de sesión exitoso'
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Error al iniciar sesión';
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Email inválido';
          break;
        case 'user-disabled':
          message = 'Usuario deshabilitado';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos. Intenta más tarde';
          break;
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // ==============================
  // REENVIAR OTP
  // ==============================
  Future<Map<String, dynamic>> resendEmailOtp(String email) async {
    try {
      final authEmail = _auth.currentUser?.email ?? '';
      if (authEmail.toLowerCase().trim() != email.toLowerCase().trim()) {
        return {
          'success': false,
          'message': 'El correo no coincide con el usuario actual.'
        };
      }

      final callable = _functions.httpsCallable('requestEmailOtp');
      await callable.call({'email': email.trim().toLowerCase()});
      return {'success': true, 'message': 'Código reenviado'};
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'message': _mapFunctionsError(e)};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo reenviar: $e'};
    }
  }

  // ==============================
  // VERIFICAR OTP
  // ==============================
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final authEmail = _auth.currentUser?.email ?? '';
      if (authEmail.toLowerCase().trim() != email.toLowerCase().trim()) {
        throw Exception('El correo no coincide con el usuario actual.');
      }

      final callable = _functions.httpsCallable('verifyEmailOtp');
      await callable.call({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      });

      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFunctionsError(e));
    } catch (e) {
      throw Exception('No se pudo verificar: $e');
    }
  }

  // ==============================
  // SINCRONIZAR emailVerified (para botón "Ya verifiqué", si lo usas)
  // ==============================
  Future<bool> refreshAndSyncEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    final fresh = _auth.currentUser!;
    if (fresh.emailVerified) {
      await _firestore
          .collection('users')
          .doc(fresh.uid)
          .set({'emailVerified': true}, SetOptions(merge: true));
      return true;
    }
    return false;
  }

  // ==============================
  // SESIÓN / ELIMINACIÓN
  // ==============================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
        return {'success': true, 'message': 'Cuenta eliminada exitosamente'};
      }
      return {'success': false, 'message': 'No hay usuario autenticado'};
    } catch (e) {
      return {'success': false, 'message': 'Error al eliminar cuenta: $e'};
    }
  }
}
