import 'package:flutter/material.dart';

/// Colores institucionales de la Universidad Continental
/// Tonos negros y blancos para una apariencia profesional
class AppColors {
  // Colores principales - Negro Continental
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color secondaryBlack = Color(0xFF2D2D2D);
  static const Color accentBlack = Color(0xFF0D0D0D);
  
  // Colores blancos
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color secondaryWhite = Color(0xFFF5F5F5);
  static const Color disabledWhite = Color(0xFFE0E0E0);
  
  // Colores de acento
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color accentBlue = Color(0xFF0066CC);
  
  // Colores de estado
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1A1A),
      Color(0xFF2D2D2D),
    ],
  );
}

/// Temas y estilos de texto
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlack,
  );
  
  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlack,
  );
  
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryBlack,
  );
}

/// Dimensiones y espaciados
class AppDimensions {
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  static const double borderRadiusSM = 8.0;
  static const double borderRadiusMD = 12.0;
  static const double borderRadiusLG = 16.0;
  static const double borderRadiusXL = 24.0;
  
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
}

/// Duraciones de animaciones
class AppDurations {
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  static const Duration splashDuration = Duration(seconds: 3);
}

/// Constantes varias de la aplicación
class AppConstants {
  // Nombre de la app
  static const String appName = 'Votación Delegado UC';
  
  // Dominio institucional válido
  static const String validEmailDomain = '@continental.edu.pe';
  
  // Timeout de sesión
  static const int sessionTimeoutMinutes = 30;
  
  // Máximo intentos de login
  static const int maxLoginAttempts = 3;
  
  // Rutas de la aplicación
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String votingRoute = '/voting';
  static const String confirmationRoute = '/confirmation';
  static const String resultsRoute = '/results';
  static const String profileRoute = '/profile';
  
  // Geofencing - Universidad Continental
  static const double ucLatitude = -12.097864;
  static const double ucLongitude = -75.201475;
  static const double geofenceRadiusMeters = 500.0; // 500 metros de radio
}
