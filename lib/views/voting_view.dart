import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../viewmodels/voting_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../data/models/candidate.dart';

/// Pantalla de votación con lista de candidatos y validación de ubicación
class VotingView extends StatefulWidget {
  const VotingView({super.key});

  @override
  State<VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends State<VotingView> {
  bool _hasAlreadyVoted = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyVoted();
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkIfAlreadyVoted();
    if (!mounted) return;
    
    _loadCandidates();
    _checkLocation();
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _loadCandidates() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VotingViewModel>().loadCandidates();
    });
  }

  void _checkLocation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VotingViewModel>().checkLocationPermission();
    });
  }

  Future<void> _checkIfAlreadyVoted() async {
    final authViewModel = context.read<AuthViewModel>();
    final firestoreService = context.read<FirestoreService>();
    
    if (authViewModel.currentUser != null) {
      final hasVoted = await firestoreService.hasUserVoted(authViewModel.currentUser!.id);
      if (mounted) {
        setState(() {
          _hasAlreadyVoted = hasVoted;
        });
      }
    }
  }

  Future<void> _submitVote() async {
    final votingViewModel = context.read<VotingViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final firestoreService = context.read<FirestoreService>();

    // Verificar nuevamente que no ha votado
    final hasVoted = await firestoreService.hasUserVoted(authViewModel.currentUser!.id);
    if (hasVoted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya ha emitido su voto anteriormente'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.pushReplacementNamed(context, AppConstants.resultsRoute);
      }
      return;
    }

    if (votingViewModel.selectedCandidate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, seleccione un candidato'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Verificar ubicación antes de votar
    if (!votingViewModel.isLocationVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(votingViewModel.errorMessage ?? 'Debe verificar su ubicación'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await votingViewModel.submitVote(
      authViewModel.currentUser!.id,
      authViewModel.currentUser!.email,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(
        context,
        AppConstants.confirmationRoute,
        arguments: votingViewModel.selectedCandidate,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(votingViewModel.errorMessage ?? 'Error al votar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final votingViewModel = context.watch<VotingViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Votación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.profileRoute);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de estado de ubicación
          _buildLocationStatusBar(votingViewModel),
          // Contenido principal
          Expanded(
            child: _buildContent(votingViewModel),
          ),
          // Botón de votar
          _buildSubmitButton(votingViewModel),
        ],
      ),
    );
  }

  Widget _buildLocationStatusBar(VotingViewModel viewModel) {
    final bool isVerified = viewModel.isLocationVerified;
    final bool isLoading = viewModel.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isVerified 
            ? AppColors.success.withOpacity(0.15)
            : AppColors.warning.withOpacity(0.15),
        border: Border.all(
          color: isVerified ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.location_on : Icons.location_off,
            color: isVerified ? AppColors.success : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Ubicación verificada' : 'Verificando ubicación...',
                  style: TextStyle(
                    color: isVerified ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (!isVerified && viewModel.errorMessage != null)
                  Text(
                    viewModel.errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (!isVerified && !isLoading)
            TextButton(
              onPressed: () => viewModel.checkLocationPermission(),
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(VotingViewModel viewModel) {
    // Pantalla de fuera de la universidad
    if (!viewModel.isLocationVerified && 
        viewModel.errorMessage != null && 
        viewModel.errorMessage!.contains('km de la universidad')) {
      return _buildOutsideUniversityView(viewModel);
    }

    if (_hasAlreadyVoted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.success),
            const SizedBox(height: 16),
            const Text(
              'Ya ha votado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, AppConstants.resultsRoute);
              },
              child: const Text('Ver Resultados'),
            ),
          ],
        ),
      );
    }

    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.hasError && !viewModel.hasCandidates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Error al cargar candidatos',
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadCandidates(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (!viewModel.hasCandidates) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote, size: 64, color: AppColors.disabledWhite),
            const SizedBox(height: 16),
            const Text(
              'No hay candidatos disponibles',
              style: TextStyle(fontSize: 16, color: AppColors.disabledWhite),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => viewModel.loadCandidates(),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.candidates.length,
      itemBuilder: (context, index) {
        final candidate = viewModel.candidates[index];
        final isSelected = viewModel.selectedCandidate?.id == candidate.id;

        return CandidateCard(
          candidate: candidate,
          isSelected: isSelected,
          onTap: () => viewModel.selectCandidate(candidate),
        );
      },
    );
  }

  Widget _buildOutsideUniversityView(VotingViewModel viewModel) {
    final distance = viewModel.errorMessage != null 
        ? RegExp(r'(\d+\.?\d*)km').firstMatch(viewModel.errorMessage!)?.group(1) ?? ''
        : '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 80,
              color: AppColors.error,
            ),
            const SizedBox(height: 24),
            const Text(
              'Ubicación no válida',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              distance.isNotEmpty 
                  ? 'Estás a ${distance}km de la Universidad Continental.\nDebes estar dentro del campus para votar.'
                  : 'Debes estar dentro del campus de la Universidad Continental para poder votar.',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.secondaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _goToLogin,
              icon: const Icon(Icons.logout),
              label: const Text('Volver al Inicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlack,
                foregroundColor: AppColors.primaryWhite,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => viewModel.checkLocationPermission(),
              child: const Text('Verificar ubicación nuevamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(VotingViewModel viewModel) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: viewModel.isLoading || _hasAlreadyVoted || !viewModel.isLocationVerified 
                ? null 
                : _submitVote,
            child: viewModel.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Confirmar Voto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de candidato
class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final bool isSelected;
  final VoidCallback onTap;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlack : AppColors.primaryWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : AppColors.disabledWhite,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 10 : 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto de perfil
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.secondaryWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.accentGold : AppColors.disabledWhite,
                ),
              ),
              child: candidate.photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
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
            const SizedBox(width: 16),
            // Información del candidato
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.fullName,
                    style: TextStyle(
                      color: isSelected ? AppColors.primaryWhite : AppColors.primaryBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppColors.accentGold.withOpacity(0.2)
                          : AppColors.secondaryWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      candidate.semester,
                      style: TextStyle(
                        color: isSelected ? AppColors.accentGold : AppColors.secondaryBlack,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    candidate.proposal,
                    style: TextStyle(
                      color: isSelected ? AppColors.secondaryWhite : AppColors.secondaryBlack,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Indicador de selección
            if (isSelected)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.accentGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppColors.primaryBlack,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
