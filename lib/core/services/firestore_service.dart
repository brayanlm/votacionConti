import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../data/models/candidate.dart';
import '../../data/models/user_model.dart';
import '../../data/models/vote.dart';

/// Servicio de Firestore para operaciones de base de datos
/// Maneja candidatos, usuarios y votos
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Colecciones
  static const String _candidatesCollection = 'candidates';
  static const String _usersCollection = 'users';
  static const String _votesCollection = 'votes';

  // ==================== CANDIDATOS ====================

  /// Obtener todos los candidatos
  /// Muestra todos los candidatos sin filtrar
  Stream<List<Candidate>> getActiveCandidates() {
    return _firestore
        .collection(_candidatesCollection)
        .snapshots()
        .map((snapshot) {
      final candidates = snapshot.docs
          .map((doc) => Candidate.fromFirestore(doc))
          .toList();
      
      // Ordenar por nombre
      candidates.sort((a, b) => a.name.compareTo(b.name));
      return candidates;
    });
  }

  /// Obtener lista de candidatos (no-stream, para ViewModels)
  /// Muestra todos los candidatos sin filtrar
  Future<List<Candidate>> getCandidatesList() async {
    try {
      final snapshot = await _firestore
          .collection(_candidatesCollection)
          .get();
      final candidates = snapshot.docs
          .map((doc) => Candidate.fromFirestore(doc))
          .toList();
      
      // Ordenar por nombre
      candidates.sort((a, b) => a.name.compareTo(b.name));
      return candidates;
    } catch (e) {
      throw Exception('Error al obtener candidatos: $e');
    }
  }

  /// Obtener candidato por ID
  Future<Candidate?> getCandidateById(String candidateId) async {
    try {
      final doc = await _firestore
          .collection(_candidatesCollection)
          .doc(candidateId)
          .get();
      if (doc.exists) {
        return Candidate.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener candidato: $e');
    }
  }

  /// Obtener contadores de votos en tiempo real
  Stream<Map<String, int>> getVoteCountsStream() {
    return _firestore
        .collection(_votesCollection)
        .snapshots()
        .map((snapshot) {
      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final candidateId = doc.data()['candidateId'] as String?;
        if (candidateId != null) {
          counts[candidateId] = (counts[candidateId] ?? 0) + 1;
        }
      }
      return counts;
    });
  }

  /// Obtener total de votos
  Stream<int> getTotalVotesStream() {
    return _firestore
        .collection(_votesCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ==================== USUARIOS ====================

  /// Obtener usuario por ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener usuario: $e');
    }
  }

  /// Crear o actualizar usuario
  Future<void> upsertUser(AppUser user) async {
    await _firestore
        .collection(_usersCollection)
        .doc(user.id)
        .set(user.toFirestore(), SetOptions(merge: true));
  }

  /// Verificar si usuario ha votado
  Future<bool> hasUserVoted(String userId) async {
    try {
      final doc = await _firestore
          .collection(_votesCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return doc.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar voto: $e');
    }
  }

  /// Verificar si usuario existe y está verificado
  Future<bool> isUserVerified(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return (data['isVerified'] as bool?) ?? false;
      }
      return false;
    } catch (e) {
      throw Exception('Error al verificar usuario: $e');
    }
  }

  // ==================== VOTOS ====================

  /// Registrar voto de forma atómica
  /// Previene votos duplicados mediante transacción
  Future<VoteResult> castVote(Vote vote) async {
    try {
      // Verificar si el usuario ya ha votado
      final existingVote = await _firestore
          .collection(_votesCollection)
          .where('userId', isEqualTo: vote.userId)
          .limit(1)
          .get();

      if (existingVote.docs.isNotEmpty) {
        return VoteResult(
          success: false,
          errorCode: 'already-voted',
          errorMessage: 'Ya ha emitido su voto anteriormente',
        );
      }

      // Usar transacción para operación atómica
      return await _firestore.runTransaction((transaction) async {
        // Verificar que el candidato existe
        final candidateRef = _firestore
            .collection(_candidatesCollection)
            .doc(vote.candidateId);
        final candidateDoc = await candidateRef.get();

        if (!candidateDoc.exists) {
          return VoteResult(
            success: false,
            errorCode: 'invalid-candidate',
            errorMessage: 'El candidato no es válido',
          );
        }

        // Crear documento de voto
        final voteRef = _firestore.collection(_votesCollection).doc();
        transaction.set(voteRef, vote.toFirestore());

        // Actualizar contador de candidato
        transaction.update(candidateRef, {
          'voteCount': FieldValue.increment(1),
        });

        // Actualizar usuario (usar set con merge para evitar error si no existe)
        final userRef = _firestore.collection(_usersCollection).doc(vote.userId);
        transaction.set(userRef, {
          'hasVoted': true,
          'votedAt': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));

        return VoteResult(
          success: true,
          vote: vote.copyWith(id: voteRef.id),
        );
      });
    } on FirebaseException catch (e) {
      return VoteResult(
        success: false,
        errorCode: e.code,
        errorMessage: 'Error de base de datos: ${e.message}',
      );
    } catch (e) {
      return VoteResult(
        success: false,
        errorCode: 'unknown-error',
        errorMessage: 'Error al registrar voto: $e',
      );
    }
  }

  /// Obtener todos los votos (solo para administradores)
  Stream<List<Vote>> getAllVotes() {
    return _firestore
        .collection(_votesCollection)
        .orderBy('votedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Vote.fromFirestore(doc))
            .toList());
  }

  // ==================== ESTADÍSTICAS ====================

  /// Obtener estadísticas de votación en tiempo real
  Stream<VotingStats> getVotingStats(int totalEligibleVoters) {
    return CombineLatestStream([
      getTotalVotesStream(),
      getActiveCandidates().map((candidates) => candidates.length),
      getVoteCountsStream(),
    ], (values) {
      final totalVotes = values[0] as int;
      final totalCandidates = values[1] as int;
      final votesByCandidate = values[2] as Map<String, int>;

      return VotingStats(
        totalVotes: totalVotes,
        totalCandidates: totalCandidates,
        participationPercentage: totalEligibleVoters > 0
            ? (totalVotes / totalEligibleVoters) * 100
            : 0.0,
        lastUpdated: DateTime.now(),
        votesByCandidate: votesByCandidate,
      );
    });
  }
}

/// Clase de resultado de voto
class VoteResult {
  final bool success;
  final Vote? vote;
  final String errorCode;
  final String errorMessage;

  VoteResult({
    required this.success,
    this.vote,
    this.errorCode = '',
    this.errorMessage = '',
  });

  bool get hasError => !success;
}
