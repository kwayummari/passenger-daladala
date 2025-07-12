// lib/features/wallet/domain/entities/wallet.dart
import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final int walletId;
  final int userId;
  final double balance;
  final String currency;
  final String status;
  final double? dailyLimit;
  final double? monthlyLimit;
  final DateTime? lastActivity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Wallet({
    required this.walletId,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.status,
    this.dailyLimit,
    this.monthlyLimit,
    this.lastActivity,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        walletId,
        userId,
        balance,
        currency,
        status,
        dailyLimit,
        monthlyLimit,
        lastActivity,
        createdAt,
        updatedAt,
      ];

  String get formattedBalance => '${balance.toStringAsFixed(0)} $currency';
  bool get isActive => status == 'active';
  bool get hasSufficientBalance => balance > 0;
  
  bool canAfford(double amount) => balance >= amount;
}