import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/core/theme/app_colors.dart';
import 'package:caddymoney/core/utils/app_localizations_temp.dart';
import 'package:caddymoney/services/merchant_service.dart';
import 'package:caddymoney/models/merchant_model.dart';
import 'package:caddymoney/services/admin_service.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  late Future<AdminOverviewMetrics> _metricsFuture;

  @override
  void initState() {
    super.initState();
    _metricsFuture = _adminService.fetchOverviewMetrics();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _metricsFuture = _adminService.fetchOverviewMetrics();
      _PendingMerchantsPanel.refreshSignal.value++;
    });
    // Let futures complete; RefreshIndicator will keep spinner until this returns.
    try {
      await _metricsFuture;
    } catch (_) {
      // UI already shows errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin ${l10n.dashboard}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                FutureBuilder<AdminOverviewMetrics>(
                  future: _metricsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.3,
                        children: List.generate(
                          4,
                          (i) => const StatsCard.loading(),
                        ),
                      );
                    }

                    if (snap.hasError) {
                      return Container(
                        padding: AppSpacing.paddingMd,
                        decoration: BoxDecoration(
                          border: Border.all(color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          'Failed to load overview metrics. Pull to refresh or tap refresh in the top bar.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    final metrics = snap.data!;
                    final countFmt = NumberFormat.decimalPattern();
                    final volumeFmt = NumberFormat.compactCurrency(symbol: '€');

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.3,
                      children: [
                        StatsCard(
                          title: l10n.totalUsers,
                          value: countFmt.format(metrics.totalUsers),
                          icon: Icons.people_outline,
                          color: AppColors.primary,
                          onTap: () {},
                        ),
                        StatsCard(
                          title: l10n.totalMerchants,
                          value: countFmt.format(metrics.totalMerchants),
                          icon: Icons.store_outlined,
                          color: AppColors.secondary,
                          onTap: () {},
                        ),
                        StatsCard(
                          title: l10n.totalTransactions,
                          value: countFmt.format(metrics.totalTransactions),
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.tertiary,
                          onTap: () {},
                        ),
                        StatsCard(
                          title: l10n.transactionVolume,
                          value: volumeFmt.format(metrics.transactionVolume),
                          icon: Icons.attach_money,
                          color: AppColors.success,
                          onTap: () {},
                        ),
                      ],
                    );
                  },
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
      ),
    );
  }
}

class _PendingMerchantsPanel extends StatefulWidget {
  const _PendingMerchantsPanel();

  static final ValueNotifier<int> refreshSignal = ValueNotifier<int>(0);

  @override
  State<_PendingMerchantsPanel> createState() => _PendingMerchantsPanelState();
}

class _PendingMerchantsPanelState extends State<_PendingMerchantsPanel> {
  final _service = MerchantService();
  late Future<({List<MerchantModel> merchants, String? error})> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listMerchantsResult(statuses: const ['pending', 'under_review'], limit: 20);
    _PendingMerchantsPanel.refreshSignal.addListener(_onRefreshSignal);
  }

  @override
  void dispose() {
    _PendingMerchantsPanel.refreshSignal.removeListener(_onRefreshSignal);
    super.dispose();
  }

  void _onRefreshSignal() {
    if (!mounted) return;
    setState(() {
      _future = _service.listMerchantsResult(statuses: const ['pending', 'under_review'], limit: 20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<MerchantModel> merchants, String? error})>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          return Text(
            'Failed to load pending merchants. Pull to refresh.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }

        final payload = snap.data;
        final items = payload?.merchants ?? const <MerchantModel>[];
        final error = payload?.error;
        if ((error ?? '').isNotEmpty && items.isEmpty) {
          return Text(
            error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
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
                onDecision: () => _PendingMerchantsPanel.refreshSignal.value++,
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
  final bool _isLoading;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : _isLoading = false;

  const StatsCard.loading({super.key})
      : title = '',
        value = '',
        icon = Icons.circle,
        color = Colors.transparent,
        onTap = _noop,
        _isLoading = true;

  static void _noop() {}

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _isLoading
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  )
                : Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _isLoading
                      ? Container(
                          width: 72,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        )
                      : Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                          ),
                        ),
                  const SizedBox(height: 6),
                  _isLoading
                      ? Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                        )
                      : Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1.15,
                          ),
                        ),
                ],
              ),
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
  final VoidCallback? onDecision;

  const MerchantApprovalItem({
    super.key,
    required this.businessName,
    required this.ownerName,
    required this.category,
    required this.submittedDate,
    this.onDecision,
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
                  onPressed: onDecision,
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
                  onPressed: onDecision,
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
