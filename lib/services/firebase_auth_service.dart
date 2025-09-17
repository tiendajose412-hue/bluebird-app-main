// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // IMPORTANTE: usa la misma región donde desplegaste las Functions
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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
        email: email,
        password: password,
      );

      final user = result.user!;

      // Guardar datos adicionales en Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'phone': phone,
        'createdAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
      }, SetOptions(merge: true));

      // Solicitar OTP por correo (Cloud Function)
      final callable = _functions.httpsCallable('requestEmailOtp');
      await callable.call({'email': email});

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
        email: email,
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
  // REENVIAR OTP (verificación de email)
  // ==============================
  Future<Map<String, dynamic>> resendEmailOtp(String email) async {
    try {
      final callable = _functions.httpsCallable('requestEmailOtp');
      await callable.call({'email': email});
      return {'success': true, 'message': 'Código reenviado'};
    } catch (e) {
      return {'success': false, 'message': 'No se pudo reenviar: $e'};
    }
  }

  // ==============================
  // VERIFICAR OTP (verificación de email)
  // ==============================
  Future<bool> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyEmailOtp');
      await callable.call({'email': email, 'code': code});
      await _auth.currentUser?.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      rethrow;
    }
  }

  // ==============================
  // SINCRONIZAR emailVerified
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
  // OLVIDÉ MI CONTRASEÑA — OTP por email
  // ==============================
  Future<Map<String, dynamic>> requestPasswordResetOtp(String email) async {
    try {
      final callable = _functions.httpsCallable('requestPasswordResetOtp');
      await callable.call({'email': email.trim().toLowerCase()});
      return {'success': true, 'message': 'Te enviamos un código a tu correo.'};
    } on FirebaseFunctionsException catch (e) {
      final msg = _mapFunctionsError(e);
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final callable = _functions.httpsCallable('resetPasswordWithOtp');
      await callable.call({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
        'newPassword': newPassword,
      });
      return {
        'success': true,
        'message': 'Contraseña actualizada. Inicia sesión.'
      };
    } on FirebaseFunctionsException catch (e) {
      final msg = _mapFunctionsError(e);
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
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

  // ==============================
  // Helpers
  // ==============================
  String _mapFunctionsError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'invalid-argument':
        // Puede venir por datos inválidos o código incorrecto
        return e.message ?? 'Datos inválidos. Revisa email/código/contraseña.';
      case 'not-found':
        return 'No existe usuario con ese email.';
      case 'failed-precondition':
        return 'No hay un código activo. Solicítalo primero.';
      case 'deadline-exceeded':
        return 'El código expiró. Pide uno nuevo.';
      case 'resource-exhausted':
        return 'Demasiados intentos o cooldown activo.';
      case 'permission-denied':
        return 'Permisos insuficientes.';
      default:
        return e.message ?? 'Error (Functions).';
    }
  }
}
