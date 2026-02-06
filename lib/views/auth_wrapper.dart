import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/services/auth_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_view.dart';
import 'home_view.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );
    final authService = Provider.of<AuthService>(
      context,
      listen: false,
    );

    // Verificar si hay un usuario autenticado
    final currentUser = authService.currentUser;
    
    if (currentUser != null) {
      // Restaurar sesión
      await authViewModel.restoreSession();
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Inicializando...'),
            ],
          ),
        ),
      );
    }

    if (authViewModel.isAuthenticated) {
      return const HomeView();
    } else {
      return const LoginView();
    }
  }
}
