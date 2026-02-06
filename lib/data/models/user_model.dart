import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de usuario verificado para la votación
class AppUser {
  final String id;
  final String email;
  final String name;
  final String lastName;
  final String fullName;
  final String studentCode;
  final String semester;
  final String career;
  final String photoURL;
  final bool hasVoted;
  final bool isVerified;
  final DateTime? lastLogin;
  final DateTime? votedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.lastName,
    required this.studentCode,
    required this.semester,
    required this.career,
    this.photoURL = '',
    this.hasVoted = false,
    this.isVerified = false,
    this.lastLogin,
    this.votedAt,
  }) : fullName = '$name $lastName';

  /// Constructor desde documento de Firestore
  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      lastName: data['lastName'] ?? '',
      studentCode: data['studentCode'] ?? '',
      semester: data['semester'] ?? '',
      career: data['career'] ?? '',
      photoURL: data['photoURL'] ?? '',
      hasVoted: (data['hasVoted'] as bool?) ?? false,
      isVerified: (data['isVerified'] as bool?) ?? false,
      lastLogin: data['lastLogin'] != null 
          ? DateTime.parse(data['lastLogin']) 
          : null,
      votedAt: data['votedAt'] != null 
          ? DateTime.parse(data['votedAt']) 
          : null,
    );
  }

  /// Constructor desde usuario de Firebase Auth
  factory AppUser.fromFirebaseUser(dynamic firebaseUser, {String? name, String? lastName}) {
    final parts = (name ?? firebaseUser.displayName ?? '').split(' ');
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: parts.isNotEmpty ? parts[0] : '',
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      studentCode: '',
      semester: '',
      career: '',
      photoURL: firebaseUser.photoURL ?? '',
    );
  }

  /// Convertir a mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'lastName': lastName,
      'studentCode': studentCode,
      'semester': semester,
      'career': career,
      'photoURL': photoURL,
      'hasVoted': hasVoted,
      'isVerified': isVerified,
      'lastLogin': lastLogin?.toIso8601String(),
      'votedAt': votedAt?.toIso8601String(),
    };
  }

  /// Crear copia con valores actualizados
  AppUser copyWith({
    String? photoURL,
    bool? hasVoted,
    bool? isVerified,
    DateTime? lastLogin,
    DateTime? votedAt,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name,
      lastName: lastName,
      studentCode: studentCode,
      semester: semester,
      career: career,
      photoURL: photoURL ?? this.photoURL,
      hasVoted: hasVoted ?? this.hasVoted,
      isVerified: isVerified ?? this.isVerified,
      lastLogin: lastLogin ?? this.lastLogin,
      votedAt: votedAt ?? this.votedAt,
    );
  }
}
