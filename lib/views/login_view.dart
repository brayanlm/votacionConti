import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de login únicamente con Google
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  Future<void> _handleGoogleLogin() async {
    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );

    final success = await authViewModel.loginWithGoogle();

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppConstants.votingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingLG,
              vertical: AppDimensions.spacingXL,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXL),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 60,
                    color: AppColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                const Text(
                  'Universidad Continental',
                  style: TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                const Text(
                  'Sistema de Votación',
                  style: TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                
                // Mensaje de error
                if (authViewModel.hasError)
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacingSM),
                    margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSM),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: AppDimensions.spacingSM),
                        Expanded(
                          child: Text(
                            authViewModel.errorMessage ?? 'Error desconocido',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Botón de Google
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton.icon(
                    onPressed: authViewModel.isLoading ? null : _handleGoogleLogin,
                    icon: const Icon(Icons.login, color: AppColors.primaryBlack),
                    label: authViewModel.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.primaryWhite,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar sesión con Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlack,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryWhite,
                      foregroundColor: AppColors.primaryBlack,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                
                // Aviso
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingSM),
                  decoration: BoxDecoration(
                    color: AppColors.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
                    border: Border.all(color: AppColors.accentGold),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.accentGold),
                      const SizedBox(width: AppDimensions.spacingSM),
                      Expanded(
                        child: Text(
                          'Solo estudiantes con correo @continental.edu.pe pueden acceder',
                          style: TextStyle(
                            color: AppColors.primaryWhite,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
