import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/core/theme/app_colors.dart';
import 'package:caddymoney/core/utils/app_localizations_temp.dart';
import 'package:caddymoney/services/merchant_service.dart';
import 'package:caddymoney/models/merchant_model.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin ${l10n.dashboard}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform Overview',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.3,
                children: [
                  StatsCard(
                    title: l10n.totalUsers,
                    value: '1,234',
                    icon: Icons.people_outline,
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  StatsCard(
                    title: l10n.totalMerchants,
                    value: '156',
                    icon: Icons.store_outlined,
                    color: AppColors.secondary,
                    onTap: () {},
                  ),
                  StatsCard(
                    title: l10n.totalTransactions,
                    value: '5,678',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.tertiary,
                    onTap: () {},
                  ),
                  StatsCard(
                    title: l10n.transactionVolume,
                    value: '€125K',
                    icon: Icons.attach_money,
                    color: AppColors.success,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AdminActionCard(
                icon: Icons.people_outline,
                title: 'Manage Users',
                subtitle: 'View and manage user accounts',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              AdminActionCard(
                icon: Icons.store_outlined,
                title: 'Manage Merchants',
                subtitle: 'Approve, reject, or suspend merchants',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.sm),
              AdminActionCard(
                icon: Icons.receipt_long_outlined,
                title: 'View All Transactions',
                subtitle: 'Monitor all platform transactions',
                onTap: () {},
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Pending Merchant Approvals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _PendingMerchantsPanel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingMerchantsPanel extends StatefulWidget {
  const _PendingMerchantsPanel();

  @override
  State<_PendingMerchantsPanel> createState() => _PendingMerchantsPanelState();
}

class _PendingMerchantsPanelState extends State<_PendingMerchantsPanel> {
  final _service = MerchantService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MerchantModel>>(
      future: _service.listMerchants(status: 'pending', limit: 20),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return Text(
            'No pending requests right now.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        return Column(
          children: items.map((m) {
            final owner = [m.ownerFirstName, m.ownerLastName].whereType<String>().where((e) => e.trim().isNotEmpty).join(' ');
            final categories = m.categories.isNotEmpty
                ? m.categories.join(', ')
                : (m.businessCategory ?? '');
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: MerchantApprovalItem(
                businessName: m.businessName,
                ownerName: owner.isNotEmpty ? owner : (m.ownerName ?? '—'),
                category: categories.isNotEmpty ? categories : '—',
                submittedDate: _relativeTime(m.createdAt),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const AdminActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantApprovalItem extends StatelessWidget {
  final String businessName;
  final String ownerName;
  final String category;
  final String submittedDate;

  const MerchantApprovalItem({
    super.key,
    required this.businessName,
    required this.ownerName,
    required this.category,
    required this.submittedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      businessName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Owner: $ownerName • $category',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  submittedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
