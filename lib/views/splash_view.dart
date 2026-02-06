import 'package:flutter/material.dart';
import 'dart:async';
import '../core/constants/app_constants.dart';

/// Pantalla de splash simple
/// Muestra el logo de la universidad y transiciona al login
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    
    Navigator.pushReplacementNamed(
      context,
      AppConstants.loginRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlack,
              AppColors.secondaryBlack,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de la universidad
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school,
                  size: 70,
                  color: AppColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Universidad Continental',
                style: TextStyle(
                  color: AppColors.primaryWhite,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Votación de Delegados',
                style: TextStyle(
                  color: AppColors.secondaryWhite,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                color: AppColors.accentGold,
              ),
              const SizedBox(height: 20),
              const Text(
                'Cargando...',
                style: TextStyle(
                  color: AppColors.secondaryWhite,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
