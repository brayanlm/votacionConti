import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/voting_viewmodel.dart';
import 'core/constants/app_constants.dart';
import 'views/splash_view.dart';
import 'views/login_view.dart';
import 'views/voting_view.dart';
import 'views/confirmation_view.dart';
import 'views/results_view.dart';
import 'views/profile_view.dart';
import 'views/home_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error al inicializar Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
        ChangeNotifierProvider<AuthViewModel>(
          create: (context) => AuthViewModel(
            authService: context.read<AuthService>(),
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
        ChangeNotifierProvider<VotingViewModel>(
          create: (context) => VotingViewModel(
            firestoreService: context.read<FirestoreService>(),
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Votación Delegado UC',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryBlack,
            primary: AppColors.primaryBlack,
            secondary: AppColors.secondaryBlack,
            surface: AppColors.primaryWhite,
            background: AppColors.secondaryWhite,
          ),
          scaffoldBackgroundColor: AppColors.secondaryWhite,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryBlack,
            foregroundColor: AppColors.primaryWhite,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlack,
              foregroundColor: AppColors.primaryWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
              ),
              minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.secondaryWhite,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMD),
              borderSide: const BorderSide(
                color: AppColors.primaryBlack,
                width: 2,
              ),
            ),
          ),
        ),
        home: const SplashView(),
        routes: {
          AppConstants.splashRoute: (_) => const SplashView(),
          AppConstants.loginRoute: (_) => const LoginView(),
          AppConstants.homeRoute: (_) => const HomeView(),
          AppConstants.votingRoute: (_) => const VotingView(),
          AppConstants.confirmationRoute: (_) => const ConfirmationView(),
          AppConstants.resultsRoute: (_) => const ResultsView(),
          AppConstants.profileRoute: (_) => const ProfileView(),
        },
      ),
    );
  }
}
