// lib/features/auth/domain/entities/user.dart
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String? email;
  final String? profilePicture;
  final String role;
  final bool isVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.email,
    this.profilePicture,
    this.role = 'passenger',
    this.isVerified = false,
    this.createdAt,
    this.lastLogin,
  });

  String get fullName => '$firstName $lastName';

  String get displayPhone {
    // Format Tanzanian phone number for display
    if (phone.startsWith('+255')) {
      return phone;
    } else if (phone.startsWith('255')) {
      return '+$phone';
    } else if (phone.startsWith('0')) {
      return '+255${phone.substring(1)}';
    }
    return phone;
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    phone,
    email,
    profilePicture,
    role,
    isVerified,
    createdAt,
    lastLogin,
  ];

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
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
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
    );
  }
}
