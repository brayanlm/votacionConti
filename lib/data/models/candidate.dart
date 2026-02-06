import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de candidato para la votación
/// Soporta campos en español e inglés de Firestore
class Candidate {
  final String id;
  final String name;
  final String lastName;
  final String fullName;
  final String photoUrl;
  final String semester;
  final String proposal;
  final int voteCount;
  final double votePercentage;
  final bool isActive;
  final DateTime? createdAt;

  Candidate({
    required this.id,
    required this.name,
    required this.lastName,
    required this.photoUrl,
    required this.semester,
    required this.proposal,
    this.voteCount = 0,
    this.votePercentage = 0.0,
    this.isActive = true,
    this.createdAt,
  }) : fullName = '$name $lastName';

  /// Constructor desde documento de Firestore
  /// Maneja campos en español e inglés
  factory Candidate.fromFirestore(DocSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Soportar campos en español e inglés
    final name = data['name'] ?? data['nombre'] ?? '';
    final lastName = data['lastName'] ?? data['apellido'] ?? '';
    final photoUrl = data['photoUrl'] ?? data['foto'] ?? '';
    final semester = data['semester'] ?? data['semestre'] ?? '';
    final proposal = data['proposal'] ?? data['propuesta'] ?? '';
    
    // Manejar voteCount (puede ser int o double)
    final voteCountRaw = data['voteCount'] ?? data['votos'] ?? 0;
    final voteCount = voteCountRaw is int ? voteCountRaw : voteCountRaw.toInt();
    
    // Manejar votePercentage (puede ser int o double)
    final votePercentageRaw = data['votePercentage'] ?? 0.0;
    final votePercentage = votePercentageRaw is double ? votePercentageRaw : votePercentageRaw.toDouble();
    
    // Manejar isActive (puede ser bool o int)
    final isActiveRaw = data['isActive'] ?? data['activo'] ?? true;
    final isActive = isActiveRaw is bool ? isActiveRaw : isActiveRaw == 1;
    
    // Parsear fecha de creación
    DateTime? createdAt;
    if (data['fechaCreacion'] != null) {
      createdAt = (data['fechaCreacion'] as Timestamp).toDate();
    } else if (data['createdAt'] != null) {
      createdAt = (data['createdAt'] as Timestamp).toDate();
    }

    return Candidate(
      id: doc.id,
      name: name,
      lastName: lastName,
      photoUrl: photoUrl,
      semester: semester,
      proposal: proposal,
      voteCount: voteCount,
      votePercentage: votePercentage,
      isActive: isActive,
      createdAt: createdAt,
    );
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'semester': semester,
      'proposal': proposal,
      'voteCount': voteCount,
      'votePercentage': votePercentage,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  /// Crear copia con contador actualizado
  Candidate copyWith({int? voteCount, double? votePercentage}) {
    return Candidate(
      id: id,
      name: name,
      lastName: lastName,
      photoUrl: photoUrl,
      semester: semester,
      proposal: proposal,
      voteCount: voteCount ?? this.voteCount,
      votePercentage: votePercentage ?? this.votePercentage,
      isActive: isActive,
      createdAt: createdAt,
    );
  }
}

/// Tipo alias para documento de Firestore
typedef DocSnapshot = DocumentSnapshot<Map<String, dynamic>>;
