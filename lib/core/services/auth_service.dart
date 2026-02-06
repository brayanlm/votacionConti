import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Servicio de autenticación con Firebase
/// Implementa Google Sign-In y validación de correo institucional
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
    ],
  );
  static const String _lastActivityKey = 'last_activity_time';
  
  // Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Usuario actual
  User? get currentUser => _auth.currentUser;

  /// Iniciar sesión con Google
  /// Muestra el popup de Google para seleccionar cuenta
  Future<AuthResult> loginWithGoogle() async {
    try {
      // Verificar conexión a Google
      await _googleSignIn.signOut();

      // Iniciar proceso de Google Sign-In
      final googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return AuthResult(
          success: false,
          errorCode: 'cancelled',
          errorMessage: 'Inicio de sesión cancelado',
        );
      }

      // Verificar que el email sea institucional
      final email = googleUser.email;
      if (!email.toLowerCase().endsWith(AppConstants.validEmailDomain)) {
        await _googleSignIn.signOut();
        return AuthResult(
          success: false,
          errorCode: 'invalid-domain',
          errorMessage: 'Solo se permiten correos institucionales (@continental.edu.pe)',
        );
      }

      // Obtener credenciales de Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Crear credencial de Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Autenticar con Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      // Guardar tiempo de última actividad
      await updateLastActivityTime();

      return AuthResult(
        success: true,
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      await _googleSignIn.signOut();
      return _handleFirebaseAuthException(e);
    } catch (e) {
      await _googleSignIn.signOut();
      return AuthResult(
        success: false,
        errorCode: 'unknown-error',
        errorMessage: 'Error al iniciar sesión con Google: $e',
      );
    }
  }

  /// Iniciar sesión con email y contraseña
  /// Valida dominio institucional antes de autenticar
  Future<AuthResult> login(String email, String password) async {
    try {
      // Validar formato de email
      if (!_isValidEmailFormat(email)) {
        return AuthResult(
          success: false,
          errorCode: 'invalid-email-format',
          errorMessage: 'El formato del correo electrónico no es válido',
        );
      }

      // Validar dominio institucional
      if (!_isInstitutionalEmail(email)) {
        return AuthResult(
          success: false,
          errorCode: 'invalid-domain',
          errorMessage: 'Solo se permiten correos institucionales (@continental.edu.pe)',
        );
      }

      // Intentar autenticación con Firebase
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      // Guardar tiempo de última actividad
      await updateLastActivityTime();

      return AuthResult(
        success: true,
        user: userCredential.user,
      );
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException(e);
    } catch (e) {
      return AuthResult(
        success: false,
        errorCode: 'unknown-error',
        errorMessage: 'Ocurrió un error inesperado. Por favor, inténtelo nuevamente.',
      );
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    try {
      // Cerrar sesión de Google primero
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _clearSessionData();
    } catch (e) {
      throw Exception('Error al cerrar sesión');
    }
  }

  /// Validar formato de email
  bool _isValidEmailFormat(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validar dominio institucional
  bool _isInstitutionalEmail(String email) {
    return email.toLowerCase().endsWith(AppConstants.validEmailDomain);
  }

  /// Manejar excepciones de Firebase Auth
  AuthResult _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthResult(
          success: false,
          errorCode: 'user-not-found',
          errorMessage: 'No existe una cuenta con este correo electrónico',
        );
      case 'wrong-password':
        return AuthResult(
          success: false,
          errorCode: 'wrong-password',
          errorMessage: 'La contraseña ingresada es incorrecta',
        );
      case 'invalid-email':
        return AuthResult(
          success: false,
          errorCode: 'invalid-email',
          errorMessage: 'El correo electrónico no es válido',
        );
      case 'user-disabled':
        return AuthResult(
          success: false,
          errorCode: 'user-disabled',
          errorMessage: 'Esta cuenta ha sido deshabilitada',
        );
      case 'too-many-requests':
        return AuthResult(
          success: false,
          errorCode: 'too-many-requests',
          errorMessage: 'Demasiados intentos fallidos. Por favor, espere unos minutos',
        );
      case 'network-request-failed':
        return AuthResult(
          success: false,
          errorCode: 'network-error',
          errorMessage: 'Error de conexión. Verifique su internet',
        );
      case 'credential-already-in-use':
        return AuthResult(
          success: false,
          errorCode: 'credential-in-use',
          errorMessage: 'Esta cuenta ya está asociada a otro método de inicio de sesión',
        );
      default:
        return AuthResult(
          success: false,
          errorCode: e.code,
          errorMessage: 'Error de autenticación: ${e.message}',
        );
    }
  }

  /// Actualizar tiempo de última actividad
  Future<void> updateLastActivityTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastActivityKey, 
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Obtener Tiempo de última actividad
  Future<int?> getLastActivityTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastActivityKey);
  }

  /// Verificar si la sesión ha expirado
  Future<bool> isSessionExpired() async {
    final lastActivity = await getLastActivityTime();
    if (lastActivity == null) return true;

    final lastActivityTime = DateTime.fromMillisecondsSinceEpoch(lastActivity);
    final expirationTime = lastActivityTime.add(
      Duration(minutes: AppConstants.sessionTimeoutMinutes),
    );

    return DateTime.now().isAfter(expirationTime);
  }

  /// Limpiar datos de sesión
  Future<void> _clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
  }

  /// Restablecer contraseña
  Future<AuthResult> resetPassword(String email) async {
    try {
      if (!_isInstitutionalEmail(email)) {
        return AuthResult(
          success: false,
          errorCode: 'invalid-domain',
          errorMessage: 'Solo se permiten correos institucionales',
        );
      }

      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return AuthResult(
        success: true,
        errorMessage: 'Se ha enviado un correo para restablecer su contraseña',
      );
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseAuthException(e);
    } catch (e) {
      return AuthResult(
        success: false,
        errorCode: 'unknown-error',
        errorMessage: 'Error al enviar correo de restablecimiento',
      );
    }
  }
}

/// Clase de resultado de autenticación
class AuthResult {
  final bool success;
  final User? user;
  final String errorCode;
  final String errorMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorCode = '',
    this.errorMessage = '',
  });

  bool get hasError => !success;
}
