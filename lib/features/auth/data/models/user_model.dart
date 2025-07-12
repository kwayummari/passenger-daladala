// lib/features/auth/data/models/user_model.dart
import '../../domain/entities/user.dart';

class UserModel extends User {
  final String? accessToken;

  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.phone,
    super.email,
    super.profilePicture,
    super.role,
    super.isVerified,
    super.createdAt,
    super.lastLogin,
    this.accessToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'passenger',
      isVerified: json['is_verified'] ?? false,
      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'])
              : null,
      lastLogin:
          json['last_login'] != null
              ? DateTime.tryParse(json['last_login'])
              : null,
      accessToken: json['accessToken'], // JWT token from backend
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'profile_picture': profilePicture,
      'role': role,
      'is_verified': isVerified,
      'created_at': createdAt?.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
      'accessToken': accessToken,
    };
  }

  UserModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? profilePicture,
    String? role,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    String? accessToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      accessToken: accessToken ?? this.accessToken,
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, firstName: $firstName, lastName: $lastName, phone: $phone, email: $email, role: $role)';
  }
}
