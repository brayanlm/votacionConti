import 'package:flutter/foundation.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';
import '../data/models/user_model.dart';

/// ViewModel de autenticación simplificado
/// Maneja el estado de sesión y operaciones de login/logout
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _currentUser;
  bool _isSessionValid = true;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isSessionValid => _isSessionValid;
  bool get hasError => _errorMessage != null;

  // Constructor
  AuthViewModel({required AuthService authService, FirestoreService? firestoreService}) 
      : _authService = authService,
        _firestoreService = firestoreService ?? FirestoreService();

  /// Iniciar sesión con Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.loginWithGoogle();

      if (result.success && result.user != null) {
        // Crear usuario desde Google
        final user = AppUser.fromFirebaseUser(
          result.user!,
          name: result.user!.displayName?.split(' ').first ?? '',
          lastName: result.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
        );
        
        _currentUser = user;
        
        // Crear o actualizar usuario en Firestore
        await _firestoreService.upsertUser(user);
        
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Iniciar sesión con email y contraseña
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await _authService.login(email, password);

      if (result.success && result.user != null) {
        // Crear usuario desde Firebase Auth
        final user = AppUser.fromFirebaseUser(
          result.user!,
          name: result.user!.displayName?.split(' ').first ?? '',
          lastName: result.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
        );
        
        _currentUser = user;
        
        // Crear o actualizar usuario en Firestore
        await _firestoreService.upsertUser(user);
        
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Cerrar sesión
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();
    _currentUser = null;
    _isSessionValid = true;
    _setLoading(false);
  }

  /// Verificar y restaurar sesión
  Future<bool> restoreSession() async {
    final user = _authService.currentUser;
    if (user == null) {
      return false;
    }

    // Verificar si sesión ha expirado
    final isExpired = await _authService.isSessionExpired();
    if (isExpired) {
      _isSessionValid = false;
      return false;
    }

    // Crear usuario desde Firebase Auth
    final appUser = AppUser.fromFirebaseUser(
      user,
      name: user.displayName?.split(' ').first ?? '',
      lastName: user.displayName?.split(' ').skip(1).join(' ') ?? '',
    );
    
    // Verificar si existe en Firestore, si no crearlo
    final existingUser = await _firestoreService.getUserById(user.uid);
    if (existingUser == null) {
      await _firestoreService.upsertUser(appUser);
    }
    
    _currentUser = existingUser ?? appUser;
    return true;
  }

  /// Verificar si usuario ha votado (desde Firestore)
  Future<bool> hasUserVoted() async {
    if (_currentUser == null) return false;
    return await _firestoreService.hasUserVoted(_currentUser!.id);
  }

  /// Actualizar tiempo de última actividad
  Future<void> updateActivity() async {
    await _authService.updateLastActivityTime();
  }

  /// Restablecer contraseña
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    final result = await _authService.resetPassword(email);
    _setLoading(false);
    
    if (result.hasError) {
      _setError(result.errorMessage);
      return false;
    }
    return true;
  }

  /// Actualizar usuario actual
  void updateCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Limpiar error
  void clearError() {
    _clearError();
  }

  // Métodos privados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
