import 'package:flutter/foundation.dart';
import '../data/models/candidate.dart';
import '../data/models/vote.dart';
import '../core/services/firestore_service.dart';
import '../core/services/geolocation_service.dart';

/// ViewModel para gestionar el estado de votación y candidatos
class VotingViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  List<Candidate> _candidates = [];
  bool _isLoading = false;
  String? _errorMessage;
  Candidate? _selectedCandidate;
  bool _isLocationVerified = false;
  bool _isCheckingLocation = false;

  // Getters
  List<Candidate> get candidates => _candidates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Candidate? get selectedCandidate => _selectedCandidate;
  bool get hasError => _errorMessage != null;
  bool get hasCandidates => _candidates.isNotEmpty;
  bool get isLocationVerified => _isLocationVerified;
  bool get canVote => _isLocationVerified && _selectedCandidate != null;

  // Constructor
  VotingViewModel({required FirestoreService firestoreService})
      : _firestoreService = firestoreService;

  /// Verificar si el usuario está dentro del campus
  Future<bool> checkLocationPermission() async {
    _setLoading(true);
    _clearError();
    _isCheckingLocation = true;

    try {
      // Verificar permisos de ubicación
      final hasPermission = await GeolocationService.requestPermission();
      if (!hasPermission) {
        _setError('Permiso de ubicación denegado. Debe permitir el acceso para votar.');
        _isLocationVerified = false;
        _isCheckingLocation = false;
        _setLoading(false);
        return false;
      }

      // Verificar si está dentro del campus
      final isWithinCampus = await GeolocationService.isWithinUniversityCampus();
      
      _isCheckingLocation = false;
      _isLocationVerified = isWithinCampus;

      if (!isWithinCampus) {
        final distance = await GeolocationService.getDistanceToUniversity();
        if (distance != null) {
          final distanceKm = (distance / 1000).toStringAsFixed(2);
          _setError('Error: Está a ${distanceKm}km de la universidad. Debe estar dentro del campus para votar.');
        } else {
          _setError('No se pudo verificar su ubicación. Asegúrese de estar en el campus.');
        }
      }

      _setLoading(false);
      return isWithinCampus;
    } catch (e) {
      _isCheckingLocation = false;
      _setError('Error al verificar ubicación: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Cargar candidatos desde Firestore
  Future<void> loadCandidates() async {
    _setLoading(true);
    _clearError();

    try {
      _candidates = await _firestoreService.getCandidatesList();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar candidatos: $e');
      _setLoading(false);
    }
  }

  /// Seleccionar un candidato
  void selectCandidate(Candidate? candidate) {
    _selectedCandidate = candidate;
    notifyListeners();
  }

  /// Enviar voto por el candidato seleccionado
  Future<bool> submitVote(String userId, String email) async {
    if (_selectedCandidate == null) {
      _setError('Por favor, seleccione un candidato');
      return false;
    }

    // Verificar ubicación antes de votar
    if (!_isLocationVerified) {
      final isValid = await checkLocationPermission();
      if (!isValid) {
        return false;
      }
    }

    _setLoading(true);
    _clearError();

    try {
      // Crear objeto Vote
      final vote = Vote(
        userId: userId,
        candidateId: _selectedCandidate!.id,
        emailHash: Vote.hashEmail(email),
        votedAt: DateTime.now(),
      );

      final result = await _firestoreService.castVote(vote);

      if (result.success) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error al enviar voto: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Limpiar selección
  void clearSelection() {
    _selectedCandidate = null;
    notifyListeners();
  }

  /// Refrescar datos
  Future<void> refresh() async {
    await loadCandidates();
  }

  // Métodos privados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
