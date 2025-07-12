
// lib/features/wallet/data/models/wallet_transaction_model.dart
import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionModel extends WalletTransaction {
  const WalletTransactionModel({
    required super.transactionId,
    required super.walletId,
    required super.userId,
    required super.type,
    required super.amount,
    required super.currency,
    required super.balanceBefore,
    required super.balanceAfter,
    super.referenceType,
    super.referenceId,
    super.externalReference,
    super.description,
    super.metadata,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      transactionId: json['transaction_id'] ?? json['id'],
      walletId: json['wallet_id'],
      userId: json['user_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] ?? 'TZS',
      balanceBefore: (json['balance_before'] as num).toDouble(),
      balanceAfter: (json['balance_after'] as num).toDouble(),
      referenceType: json['reference_type'],
      referenceId: json['reference_id'],
      externalReference: json['external_reference'],
      description: json['description'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transaction_id': transactionId,
      'wallet_id': walletId,
      'user_id': userId,
      'type': type,
      'amount': amount,
      'currency': currency,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'external_reference': externalReference,
      'description': description,
      'metadata': metadata,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}