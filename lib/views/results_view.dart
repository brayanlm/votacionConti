import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../data/models/candidate.dart';
import '../data/models/vote.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de resultados en tiempo real
class ResultsView extends StatelessWidget {
  const ResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    const totalEligibleVoters = 1000; // Este valor debería venir de configuración

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados en Tiempo Real'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.profileRoute);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authViewModel = Provider.of<AuthViewModel>(
                context,
                listen: false,
              );
              await authViewModel.logout();
              Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
            },
          ),
        ],
      ),
      body: StreamBuilder<VotingStats>(
        stream: firestoreService.getVotingStats(totalEligibleVoters),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = snapshot.data ?? VotingStats();

          return Column(
            children: [
              // Encabezado con estadísticas
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingLG),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlack,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.how_to_vote,
                          value: stats.totalVotes.toString(),
                          label: 'Votos Totales',
                          color: AppColors.accentGold,
                        ),
                        _StatItem(
                          icon: Icons.people,
                          value: '${stats.participationPercentage.toStringAsFixed(1)}%',
                          label: 'Participación',
                          color: AppColors.success,
                        ),
                        _StatItem(
                          icon: Icons.people_alt,
                          value: stats.totalCandidates.toString(),
                          label: 'Candidatos',
                          color: AppColors.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    Text(
                      'Última actualización: ${_formatTime(stats.lastUpdated)}',
                      style: TextStyle(
                        color: AppColors.secondaryWhite.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de candidatos con barras de progreso
              Expanded(
                child: StreamBuilder<List<Candidate>>(
                  stream: firestoreService.getActiveCandidates(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final candidates = snapshot.data ?? [];
                    final totalVotes = candidates.fold<int>(
                      0,
                      (sum, c) => sum + c.voteCount,
                    );

                    return ListView.builder(
                      padding: const EdgeInsets.all(AppDimensions.spacingMD),
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final percentage = totalVotes > 0
                            ? (candidate.voteCount / totalVotes) * 100
                            : 0.0;

                        return ResultCard(
                          candidate: candidate,
                          percentage: percentage,
                          voteCount: candidate.voteCount,
                          isLeading: index == 0 &&
                              candidates.isNotEmpty &&
                              candidates[0].voteCount > 0,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return 'Ahora mismo';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Widget de elemento de estadística
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primaryWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryWhite.withOpacity(0.7),
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Tarjeta de resultado de candidato
class ResultCard extends StatelessWidget {
  final Candidate candidate;
  final double percentage;
  final int voteCount;
  final bool isLeading;

  const ResultCard({
    super.key,
    required this.candidate,
    required this.percentage,
    required this.voteCount,
    this.isLeading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      elevation: isLeading ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusLG),
        side: isLeading
            ? const BorderSide(color: AppColors.accentGold, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingMD),
        child: Column(
          children: [
            Row(
              children: [
                // Foto
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryWhite,
                    borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
                    border: isLeading
                        ? Border.all(color: AppColors.accentGold, width: 2)
                        : null,
                  ),
                  child: candidate.photoUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
                          child: Image.network(
                            candidate.photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.person,
                              size: 30,
                              color: AppColors.disabledWhite,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: isLeading
                              ? AppColors.primaryBlack
                              : AppColors.disabledWhite,
                        ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),
                // Información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              candidate.fullName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isLeading
                                    ? AppColors.primaryBlack
                                    : AppColors.secondaryBlack,
                              ),
                            ),
                          ),
                          if (isLeading)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingSM,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accentGold,
                                borderRadius:
                                    BorderRadius.circular(AppDimensions.borderRadiusSM),
                              ),
                              child: const Text(
                                'LÍDER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlack,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        candidate.semester,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryBlack.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                // Porcentaje
                Column(
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isLeading
                            ? AppColors.primaryBlack
                            : AppColors.secondaryBlack,
                      ),
                    ),
                    Text(
                      '$voteCount votos',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryBlack.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            // Barra de progreso
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryWhite,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: 12,
                  width: percentage > 0
                      ? MediaQuery.of(context).size.width * 0.75 * (percentage / 100)
                      : 0,
                  decoration: BoxDecoration(
                    color: isLeading ? AppColors.accentGold : AppColors.primaryBlack,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
