import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Modelo de voto registrado
class Vote {
  final String id;
  final String userId;
  final String candidateId;
  final String emailHash;
  final DateTime votedAt;
  final bool isValid;
  final Map<String, dynamic> metadata;

  Vote({
    this.id = '',
    required this.userId,
    required this.candidateId,
    required this.emailHash,
    required this.votedAt,
    this.isValid = true,
    this.metadata = const {},
  });

  /// Constructor desde documento de Firestore
  factory Vote.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Vote(
      id: doc.id,
      userId: data['userId'] ?? '',
      candidateId: data['candidateId'] ?? '',
      emailHash: data['emailHash'] ?? '',
      votedAt: data['votedAt'] != null 
          ? (data['votedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isValid: (data['isValid'] as bool?) ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Generar hash del email para verificación de integridad
  static String hashEmail(String email) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'candidateId': candidateId,
      'emailHash': emailHash,
      'votedAt': Timestamp.fromDate(votedAt),
      'isValid': isValid,
      'metadata': metadata,
    };
  }

  /// Crear copia con valores actualizados
  Vote copyWith({
    String? id,
    String? userId,
    String? candidateId,
    String? emailHash,
    DateTime? votedAt,
    bool? isValid,
    Map<String, dynamic>? metadata,
  }) {
    return Vote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      candidateId: candidateId ?? this.candidateId,
      emailHash: emailHash ?? this.emailHash,
      votedAt: votedAt ?? this.votedAt,
      isValid: isValid ?? this.isValid,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Modelo de estadísticas de votación
class VotingStats {
  final int totalVotes;
  final int totalCandidates;
  final double participationPercentage;
  final DateTime? lastUpdated;
  final Map<String, int> votesByCandidate;

  VotingStats({
    this.totalVotes = 0,
    this.totalCandidates = 0,
    this.participationPercentage = 0.0,
    this.lastUpdated,
    this.votesByCandidate = const {},
  });

  /// Calcular porcentaje de participación
  static double calculateParticipation(int totalVotes, int totalEligible) {
    if (totalEligible == 0) return 0.0;
    return (totalVotes / totalEligible) * 100;
  }

  /// Crear copia con valores actualizados
  VotingStats copyWith({
    int? totalVotes,
    int? totalCandidates,
    double? participationPercentage,
    DateTime? lastUpdated,
    Map<String, int>? votesByCandidate,
  }) {
    return VotingStats(
      totalVotes: totalVotes ?? this.totalVotes,
      totalCandidates: totalCandidates ?? this.totalCandidates,
      participationPercentage: participationPercentage ?? this.participationPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      votesByCandidate: votesByCandidate ?? this.votesByCandidate,
    );
  }
}
