import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../data/models/candidate.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de confirmación de voto
class ConfirmationView extends StatelessWidget {
  const ConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final candidate = ModalRoute.of(context)!.settings.arguments as Candidate?;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de éxito
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.primaryWhite,
                    size: 70,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXL),
                const Text(
                  '¡Voto Registrado!',
                  style: TextStyle(
                    color: AppColors.primaryWhite,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                const Text(
                  'Gracias por participar en la votación',
                  style: TextStyle(
                    color: AppColors.secondaryWhite,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.spacingXXL),
                // Tarjeta de confirmación
                Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingLG),
                  decoration: BoxDecoration(
                    color: AppColors.primaryWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ha votado por:',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryBlack,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingMD),
                      if (candidate != null) ...[
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.secondaryWhite,
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
                            border: Border.all(color: AppColors.primaryBlack),
                          ),
                          child: candidate.photoUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
                                  child: Image.network(
                                    candidate.photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: AppColors.disabledWhite,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.disabledWhite,
                                ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        Text(
                          candidate.fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingSM,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryWhite,
                            borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSM),
                          ),
                          child: Text(
                            candidate.semester,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryBlack,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.spacingMD),
                      const Divider(),
                      const SizedBox(height: AppDimensions.spacingSM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.info_outline, size: 16, color: AppColors.info),
                          SizedBox(width: AppDimensions.spacingXS),
                          Text(
                            'Su voto ha sido registrado de forma segura',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXXL),
                // Botón para ver resultados
                SizedBox(
                  width: double.infinity,
                  height: AppDimensions.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppConstants.resultsRoute,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      foregroundColor: AppColors.primaryBlack,
                    ),
                    child: const Text(
                      'Ver Resultados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Botón para cerrar sesión
                TextButton(
                  onPressed: () async {
                    await authViewModel.logout();
                    Navigator.pushReplacementNamed(
                      context,
                      AppConstants.loginRoute,
                    );
                  },
                  child: const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: AppColors.primaryWhite,
                      fontSize: 14,
                    ),
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
