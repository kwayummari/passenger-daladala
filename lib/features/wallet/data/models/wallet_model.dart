
// lib/features/wallet/data/models/wallet_model.dart
import '../../domain/entities/wallet.dart';

class WalletModel extends Wallet {
  const WalletModel({
    required super.walletId,
    required super.userId,
    required super.balance,
    required super.currency,
    required super.status,
    super.dailyLimit,
    super.monthlyLimit,
    super.lastActivity,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['wallet_id'] ?? json['id'],
      userId: json['user_id'],
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] ?? 'TZS',
      status: json['status'] ?? 'active',
      dailyLimit: json['daily_limit']?.toDouble(),
      monthlyLimit: json['monthly_limit']?.toDouble(),
      lastActivity: json['last_activity'] != null 
          ? DateTime.parse(json['last_activity'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'user_id': userId,
      'balance': balance,
      'currency': currency,
      'status': status,
      'daily_limit': dailyLimit,
      'monthly_limit': monthlyLimit,
      'last_activity': lastActivity?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
