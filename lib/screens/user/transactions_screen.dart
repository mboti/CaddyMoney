import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:caddymoney/core/theme/app_colors.dart';
import 'package:caddymoney/core/enums/transaction_type.dart';
import 'package:caddymoney/models/transaction_model.dart';
import 'package:caddymoney/services/transaction_service.dart';
import 'package:caddymoney/core/config/supabase_config.dart';
import 'package:caddymoney/theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionService _service = TransactionService();

  bool _loading = true;
  List<TransactionModel> _items = const [];
  // Default to Incoming so users land on received transfers first.
  TransactionsDirectionFilter _filter = TransactionsDirectionFilter.incoming;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.listMyTransactions();
      if (!mounted) return;
      setState(() => _items = list);
    } catch (e) {
      debugPrint('TransactionsScreen._load failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final uid = SupabaseConfig.auth.currentUser?.id;

    List<TransactionModel> filteredItems() {
      if (uid == null) return _items;
      switch (_filter) {
        case TransactionsDirectionFilter.all:
          return _items;
        case TransactionsDirectionFilter.incoming:
          return _items.where((t) => t.receiverProfileId == uid).toList(growable: false);
        case TransactionsDirectionFilter.outgoing:
          return _items.where((t) => t.receiverProfileId != uid).toList(growable: false);
      }
    }

    final filtered = filteredItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh, color: cs.onSurface),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? ListView(
                      padding: AppSpacing.paddingLg,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        Icon(Icons.receipt_long, size: 44, color: cs.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text('No transactions yet', style: tt.titleMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 6),
                        Text(
                          'When you send or receive money, it will appear here for both accounts.',
                          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : filtered.isEmpty
                      ? ListView(
                          padding: AppSpacing.paddingLg,
                          children: [
                            TransactionsDirectionFilterBar(
                              value: _filter,
                              onChanged: (v) => setState(() => _filter = v),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Icon(Icons.filter_list_off, size: 44, color: cs.onSurfaceVariant),
                            const SizedBox(height: AppSpacing.md),
                            Text('No transactions for this filter', style: tt.titleMedium, textAlign: TextAlign.center),
                            const SizedBox(height: 6),
                            Text(
                              'Try switching back to “All” to see everything.',
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: AppSpacing.paddingLg,
                          itemCount: filtered.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return TransactionsDirectionFilterBar(
                                value: _filter,
                                onChanged: (v) => setState(() => _filter = v),
                              );
                            }
                            final t = filtered[index - 1];
                            final isCredit = uid != null && t.receiverProfileId == uid;
                            return TransactionListTile(transaction: t, isCredit: isCredit);
                          },
                        ),
        ),
      ),
    );
  }
}

enum TransactionsDirectionFilter { all, incoming, outgoing }

class TransactionsDirectionFilterBar extends StatelessWidget {
  final TransactionsDirectionFilter value;
  final ValueChanged<TransactionsDirectionFilter> onChanged;

  const TransactionsDirectionFilterBar({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: SegmentedButton<TransactionsDirectionFilter>(
        segments: const [
          ButtonSegment(value: TransactionsDirectionFilter.incoming, label: Text('Incoming'), icon: Icon(Icons.arrow_downward)),
          ButtonSegment(value: TransactionsDirectionFilter.outgoing, label: Text('Outgoing'), icon: Icon(Icons.arrow_upward)),
          ButtonSegment(value: TransactionsDirectionFilter.all, label: Text('All'), icon: Icon(Icons.view_list)),
        ],
        selected: {value},
        onSelectionChanged: (set) {
          if (set.isEmpty) return;
          onChanged(set.first);
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(tt.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.onPrimary;
            return cs.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.primary;
            return cs.surfaceContainerHighest.withValues(alpha: 0.18);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            final c = cs.outlineVariant.withValues(alpha: states.contains(WidgetState.selected) ? 0 : 0.35);
            return BorderSide(color: c);
          }),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(999))),
        ),
      ),
    );
  }
}

class TransactionListTile extends StatelessWidget {
  final TransactionModel transaction;
  final bool isCredit;

  const TransactionListTile({super.key, required this.transaction, required this.isCredit});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final amountColor = isCredit ? AppColors.transactionReceived : AppColors.transactionSent;
    final icon = isCredit ? Icons.arrow_downward : Icons.arrow_upward;
    final title = _titleFor(transaction.type, isCredit);
    final subtitle = _subtitleFor(transaction);

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              color: amountColor.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: amountColor),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: tt.titleMedium, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Text(
                      '${isCredit ? '+' : '-'}€${transaction.amount.toStringAsFixed(2)}',
                      style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: amountColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                if (_paymentSummary(transaction) != null) ...[
                  const SizedBox(height: 6),
                  _PaymentPill(text: _paymentSummary(transaction)!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _titleFor(TransactionType type, bool isCredit) {
    switch (type) {
      case TransactionType.userToUser:
        return isCredit ? 'Incoming transfer' : 'Outgoing transfer';
      case TransactionType.userToMerchant:
        return 'Merchant payment';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  static String _subtitleFor(TransactionModel t) {
    final date = _formatTime(t.createdAt);
    final ref = t.transactionReference;
    final note = (t.note ?? '').trim();
    if (note.isEmpty) return '$ref • $date';
    return '$ref • $date • $note';
  }

  static String _formatTime(DateTime dt) {
    final d = dt.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  static String? _paymentSummary(TransactionModel t) {
    final m = t.metadata;
    if (m == null) return null;
    final pm = m['payment_method'];
    if (pm is! Map) return null;
    final brand = pm['brand']?.toString();
    final last4 = pm['last4']?.toString();
    if (brand == null || last4 == null) return null;
    return '${brand.toUpperCase()} •••• $last4';
  }
}

class _PaymentPill extends StatelessWidget {
  final String text;
  const _PaymentPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.credit_card, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
