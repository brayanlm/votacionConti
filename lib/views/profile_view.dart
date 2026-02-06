import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de perfil del usuario con foto de Google
class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _hasVoted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkVotingStatus();
  }

  Future<void> _checkVotingStatus() async {
    final authViewModel = context.read<AuthViewModel>();
    final firestoreService = context.read<FirestoreService>();
    
    if (authViewModel.currentUser != null) {
      final hasVoted = await firestoreService.hasUserVoted(authViewModel.currentUser!.id);
      if (mounted) {
        setState(() {
          _hasVoted = hasVoted;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final user = authViewModel.currentUser;
    final googlePhotoUrl = user?.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlack,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Encabezado con foto de Google
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                      decoration: const BoxDecoration(
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Foto de perfil de Google
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accentGold,
                                width: 4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: googlePhotoUrl != null && googlePhotoUrl.isNotEmpty
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: googlePhotoUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.accentGold,
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => _buildDefaultAvatar(),
                                    ),
                                  )
                                : _buildDefaultAvatar(),
                          ),
                          const SizedBox(height: 16),
                          // Nombre del usuario
                          Text(
                            user?.fullName ?? 'Estudiante',
                            style: const TextStyle(
                              color: AppColors.primaryWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Email
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryWhite.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user?.email ?? '',
                              style: TextStyle(
                                color: AppColors.secondaryWhite.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Información del perfil
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Información Personal'),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            icon: Icons.badge_outlined,
                            label: 'Código de Estudiante',
                            value: user?.studentCode.isNotEmpty == true 
                                ? user!.studentCode 
                                : _extractStudentCode(user?.email ?? ''),
                          ),
                          const SizedBox(height: 10),
                          _buildInfoCard(
                            icon: Icons.school_outlined,
                            label: 'Carrera',
                            value: user?.career.isNotEmpty == true 
                                ? user!.career 
                                : 'No registrada',
                          ),
                          const SizedBox(height: 10),
                          _buildInfoCard(
                            icon: Icons.calendar_month_outlined,
                            label: 'Semestre',
                            value: user?.semester.isNotEmpty == true 
                                ? user!.semester 
                                : 'Por definir',
                          ),
                          const SizedBox(height: 20),
                          _buildSectionTitle('Estado de Votación'),
                          const SizedBox(height: 12),
                          _buildVotingStatusCard(),
                          const SizedBox(height: 24),
                          // Botón de cerrar sesión
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await authViewModel.logout();
                                Navigator.pushReplacementNamed(
                                  context,
                                  AppConstants.loginRoute,
                                );
                              },
                              icon: const Icon(Icons.logout, color: AppColors.primaryWhite),
                              label: const Text(
                                'Cerrar Sesión',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: AppColors.primaryWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryWhite,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 50,
        color: AppColors.primaryBlack,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.accentGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondaryWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.disabledWhite.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlack.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlack, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingStatusCard() {
    return GestureDetector(
      onTap: _checkVotingStatus,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: _hasVoted
              ? LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.1),
                    AppColors.success.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    AppColors.warning.withOpacity(0.1),
                    AppColors.warning.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasVoted ? AppColors.success : AppColors.warning,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hasVoted ? AppColors.success : AppColors.warning,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_hasVoted ? AppColors.success : AppColors.warning).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _hasVoted ? Icons.check : Icons.hourglass_empty,
                color: AppColors.primaryWhite,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasVoted ? 'Voto Registrado' : 'Pendiente de Votar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _hasVoted ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hasVoted
                        ? 'Su voto ha sido registrado correctamente'
                        : 'Aún no ha participado en la votación',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryBlack,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: _hasVoted ? AppColors.success : AppColors.warning),
              onPressed: _checkVotingStatus,
            ),
          ],
        ),
      ),
    );
  }

  String _extractStudentCode(String email) {
    if (email.isEmpty) return 'No registrado';
    final parts = email.split('@');
    if (parts.isNotEmpty && parts[0].length > 2) {
      return parts[0].substring(2);
    }
    return 'No registrado';
  }
}
