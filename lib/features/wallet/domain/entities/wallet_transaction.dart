
// lib/features/wallet/domain/entities/wallet_transaction.dart
import 'package:equatable/equatable.dart';

class WalletTransaction extends Equatable {
  final int transactionId;
  final int walletId;
  final int userId;
  final String type;
  final double amount;
  final String currency;
  final double balanceBefore;
  final double balanceAfter;
  final String? referenceType;
  final int? referenceId;
  final String? externalReference;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WalletTransaction({
    required this.transactionId,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.balanceBefore,
    required this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.externalReference,
    this.description,
    this.metadata,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        transactionId,
        walletId,
        userId,
        type,
        amount,
        currency,
        balanceBefore,
        balanceAfter,
        referenceType,
        referenceId,
        externalReference,
        description,
        metadata,
        status,
        createdAt,
        updatedAt,
      ];

  String get formattedAmount => '${amount.toStringAsFixed(0)} $currency';
  
  String get displayType {
    switch (type) {
      case 'topup':
        return 'Top-up';
      case 'payment':
        return 'Payment';
      case 'refund':
        return 'Refund';
      case 'transfer_in':
        return 'Transfer In';
      case 'transfer_out':
        return 'Transfer Out';
      case 'cashback':
        return 'Cashback';
      default:
        return type.toUpperCase();
    }
  }

  String get displayStatus {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  bool get isCredit => ['topup', 'refund', 'transfer_in', 'cashback'].contains(type);
  bool get isDebit => ['payment', 'transfer_out'].contains(type);
  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isFailed => ['failed', 'cancelled'].contains(status);
}