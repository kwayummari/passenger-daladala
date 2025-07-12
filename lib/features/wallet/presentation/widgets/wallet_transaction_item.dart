// lib/features/wallet/presentation/widgets/wallet_transaction_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/wallet_transaction.dart';

class WalletTransactionItem extends StatelessWidget {
  final WalletTransaction transaction;
  final bool showDivider;

  const WalletTransactionItem({
    super.key,
    required this.transaction,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Transaction icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIcon(), color: _getIconColor(), size: 24),
              ),
              const SizedBox(width: 16),

              // Transaction details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.displayType,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.description ?? 'No description',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format(transaction.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Amount and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${transaction.isCredit ? '+' : '-'}${transaction.formattedAmount}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: transaction.isCredit ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.displayStatus,
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, indent: 80, color: Colors.grey.shade200),
      ],
    );
  }

  IconData _getIcon() {
    switch (transaction.type) {
      case 'topup':
        return Icons.add_circle_outline;
      case 'payment':
        return Icons.payment;
      case 'refund':
        return Icons.refresh;
      case 'transfer_in':
        return Icons.call_received;
      case 'transfer_out':
        return Icons.call_made;
      case 'cashback':
        return Icons.card_giftcard;
      default:
        return Icons.receipt;
    }
  }

  Color _getIconColor() {
    switch (transaction.type) {
      case 'topup':
        return Colors.green;
      case 'payment':
        return Colors.blue;
      case 'refund':
        return Colors.orange;
      case 'transfer_in':
        return Colors.teal;
      case 'transfer_out':
        return Colors.purple;
      case 'cashback':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor() {
    switch (transaction.status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
