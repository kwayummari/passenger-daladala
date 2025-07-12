// lib/features/wallet/presentation/pages/wallet_page.dart
import 'package:daladala_smart_app/core/di/service_locator.dart';
import 'package:daladala_smart_app/features/wallet/data/datasource/wallet_datasource.dart';
import 'package:daladala_smart_app/features/wallet/presentation/widgets/wallet_topup_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/widgets/custom_button.dart';
import '../../../../core/ui/widgets/loading_indicator.dart';
import '../../../../core/ui/widgets/empty_state.dart';
import '../../../../core/ui/widgets/error_view.dart';
import '../providers/wallet_provider.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_transaction_item.dart';
import '../widgets/wallet_quick_actions.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWalletData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.refreshWallet();
  }

  Future<void> _refreshWallet() async {
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    await walletProvider.refreshWallet();
  }

  void _navigateToTopUp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletTopUpPage()),
    ).then((_) => _refreshWallet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Transactions')],
        ),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, walletProvider, child) {
          if (walletProvider.isLoading && !walletProvider.hasWallet) {
            return const Center(child: LoadingIndicator());
          }

          if (walletProvider.error != null && !walletProvider.hasWallet) {
            return GenericErrorView(
              message: walletProvider.error!,
              onRetry: _refreshWallet,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(walletProvider),
              _buildTransactionsTab(walletProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(WalletProvider walletProvider) {
    return RefreshIndicator(
      onRefresh: _refreshWallet,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Card
            WalletBalanceCard(
              balance: walletProvider.balance,
              currency: walletProvider.wallet?.currency ?? 'TZS',
              isLoading: walletProvider.isLoading,
            ),

            const SizedBox(height: 24),

            // Quick Actions
            WalletQuickActions(
              onTopUp: _navigateToTopUp,
              onSend: () {
                // TODO: Implement send money
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Send money feature coming soon'),
                  ),
                );
              },
              onHistory: () {
                _tabController.animateTo(1);
              },
            ),

            const SizedBox(height: 24),

            // Recent Transactions
            _buildRecentTransactions(walletProvider),

            const SizedBox(height: 24),

            // Wallet Info
            _buildWalletInfo(walletProvider),

            const SizedBox(height: 24),

            // Security Info
            _buildSecurityInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(WalletProvider walletProvider) {
    return RefreshIndicator(
      onRefresh: _refreshWallet,
      child: Container(
        color: Colors.white,
        child:
            walletProvider.transactions == null
                ? const Center(child: LoadingIndicator())
                : walletProvider.transactions!.isEmpty
                ? const EmptyState(
                  title: 'No Transactions',
                  message: 'No wallet transactions found.',
                  // icon: Icons.receipt_long,
                )
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: walletProvider.transactions!.length,
                  itemBuilder: (context, index) {
                    final transaction = walletProvider.transactions![index];
                    return WalletTransactionItem(transaction: transaction);
                  },
                ),
      ),
    );
  }

  Widget _buildRecentTransactions(WalletProvider walletProvider) {
    if (walletProvider.transactions == null ||
        walletProvider.transactions!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Top Up Wallet',
              onPressed: _navigateToTopUp,
            ),
          ],
        ),
      );
    }

    final recentTransactions = walletProvider.transactions!.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...recentTransactions.map(
            (transaction) => WalletTransactionItem(
              transaction: transaction,
              showDivider: transaction != recentTransactions.last,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletInfo(WalletProvider walletProvider) {
    final wallet = walletProvider.wallet;
    if (wallet == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Status',
            wallet.status.toUpperCase(),
            statusColor: wallet.isActive ? Colors.green : Colors.orange,
          ),
          _buildInfoRow('Currency', wallet.currency),
          if (wallet.dailyLimit != null)
            _buildInfoRow(
              'Daily Limit',
              '${wallet.dailyLimit!.toStringAsFixed(0)} ${wallet.currency}',
            ),
          if (wallet.monthlyLimit != null)
            _buildInfoRow(
              'Monthly Limit',
              '${wallet.monthlyLimit!.toStringAsFixed(0)} ${wallet.currency}',
            ),
          if (wallet.lastActivity != null)
            _buildInfoRow(
              'Last Activity',
              DateFormat('MMM dd, yyyy HH:mm').format(wallet.lastActivity!),
            ),
          _buildInfoRow(
            'Created',
            DateFormat('MMM dd, yyyy').format(wallet.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Row(
            children: [
              if (statusColor != null)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: statusColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security & Safety',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Your wallet is protected with bank-level security\n'
            '• All transactions are encrypted and monitored\n'
            '• Daily and monthly spending limits help protect you\n'
            '• Contact support immediately if you notice suspicious activity',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Add this to your main app navigation or as a separate route
class WalletNavigationHelper {
  static void navigateToWallet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => ChangeNotifierProvider(
              create:
                  (context) => WalletProvider(
                    walletDataSource: getIt<WalletDataSource>(),
                  ),
              child: const WalletPage(),
            ),
      ),
    );
  }
}

// Enhanced Payment Page Integration
// Update your existing payment page to include wallet option

class EnhancedPaymentMethodOption extends StatelessWidget {
  final String name;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final bool enabled;
  final String? disabledMessage;
  final String? badge;
  final Color? badgeColor;
  final Widget? trailing;

  const EnhancedPaymentMethodOption({
    super.key,
    required this.name,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
    this.disabledMessage,
    this.badge,
    this.badgeColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:
              isSelected && enabled
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : enabled
                  ? Colors.white
                  : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected && enabled
                    ? AppTheme.primaryColor
                    : enabled
                    ? Colors.grey.shade300
                    : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected && enabled
                        ? AppTheme.primaryColor
                        : enabled
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color:
                    isSelected && enabled
                        ? Colors.white
                        : enabled
                        ? AppTheme.primaryColor
                        : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color:
                              enabled
                                  ? (isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimaryColor)
                                  : Colors.grey.shade600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor ?? Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? description : disabledMessage ?? description,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          enabled
                              ? AppTheme.textSecondaryColor
                              : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null) ...[
              if (enabled)
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: AppTheme.primaryColor,
                )
              else
                Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
