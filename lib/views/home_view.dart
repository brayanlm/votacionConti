import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/services/firestore_service.dart';
import '../viewmodels/auth_viewmodel.dart';

/// Pantalla de inicio que redirige según el estado del usuario
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirectUser();
    });
  }

  Future<void> _redirectUser() async {
    final authViewModel = Provider.of<AuthViewModel>(
      context,
      listen: false,
    );
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    // Verificar si el usuario ha iniciado sesión
    if (!authViewModel.isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
      }
      return;
    }

    // Verificar si ya votó consultando a Firestore
    final hasVoted = await firestoreService.hasUserVoted(authViewModel.currentUser!.id);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (hasVoted) {
      Navigator.pushReplacementNamed(context, AppConstants.resultsRoute);
    } else {
      Navigator.pushReplacementNamed(context, AppConstants.votingRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Verificando estado de votación...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
