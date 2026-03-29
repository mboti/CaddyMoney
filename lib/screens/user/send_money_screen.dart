import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:caddymoney/models/payment_method_model.dart';
import 'package:caddymoney/models/saved_recipient_model.dart';
import 'package:caddymoney/services/recipient_service.dart';
import 'package:caddymoney/services/payment_method_service.dart';
import 'package:caddymoney/services/transaction_service.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/nav.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _recipientEmailController = TextEditingController();
  final _amountController = TextEditingController();
  final _addRecipientEmailController = TextEditingController();
  final _noteController = TextEditingController();

  final RecipientService _recipientService = RecipientService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final TransactionService _transactionService = TransactionService();

  bool _loadingRecipients = true;
  bool _addingRecipient = false;
  bool _savingRecipient = false;
  List<SavedRecipientModel> _recipients = const [];

  bool _loadingPaymentMethods = true;
  List<PaymentMethodModel> _paymentMethods = const [];
  String? _selectedPaymentMethodId;

  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _loadRecipients();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _recipientEmailController.dispose();
    _amountController.dispose();
    _addRecipientEmailController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    setState(() => _loadingRecipients = true);
    try {
      final list = await _recipientService.listMyRecipients();
      if (!mounted) return;
      setState(() => _recipients = list);
    } catch (e) {
      debugPrint('SendMoneyScreen._loadRecipients failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loadingRecipients = false);
    }
  }

  Future<void> _loadPaymentMethods() async {
    setState(() => _loadingPaymentMethods = true);
    try {
      final list = await _paymentMethodService.listMyPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods = list;
        if (_selectedPaymentMethodId == null && list.isNotEmpty) {
          _selectedPaymentMethodId = list.firstWhere((m) => m.isDefault, orElse: () => list.first).id;
        }
        if (_selectedPaymentMethodId != null && list.indexWhere((m) => m.id == _selectedPaymentMethodId) == -1) {
          _selectedPaymentMethodId = list.isNotEmpty ? list.firstWhere((m) => m.isDefault, orElse: () => list.first).id : null;
        }
      });
    } catch (e) {
      debugPrint('SendMoneyScreen._loadPaymentMethods failed: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loadingPaymentMethods = false);
    }
  }
  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  double? _parseAmount(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _handleSend() async {
    if (_sending) return;

    final recipientEmail = _recipientEmailController.text.trim();
    final amount = _parseAmount(_amountController.text);

    if (recipientEmail.isEmpty) {
      _showMessage('Please enter a recipient email.');
      return;
    }
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount.');
      return;
    }
    if (_selectedPaymentMethodId == null) {
      _showMessage('Please choose a payment method.');
      return;
    }

    setState(() => _sending = true);
    try {
      final receiverId = await _transactionService.findActiveUserIdByEmail(recipientEmail);
      if (!mounted) return;
      if (receiverId == null) {
        _showMessage('No matching user found for that email.');
        return;
      }

      final res = await _transactionService.transferUserToUser(
        receiverUserId: receiverId,
        amount: amount,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        paymentMethodId: _selectedPaymentMethodId,
      );

      if (!mounted) return;
      if (!res.success) {
        _showMessage(res.error ?? 'Transfer failed');
        return;
      }

      _amountController.clear();
      _noteController.clear();

      _showMessage('Transfer complete: ${res.transactionReference ?? ''}'.trim());
    } catch (e) {
      debugPrint('SendMoneyScreen._handleSend failed: $e');
      if (!mounted) return;
      _showMessage('Transfer failed');
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }
  Future<void> _handleAddRecipient() async {
    if (_savingRecipient) return;
    setState(() => _savingRecipient = true);
    try {
      final res = await _recipientService.addRecipientByEmail(_addRecipientEmailController.text);
      if (!mounted) return;
      _showMessage(res.message ?? (res.success ? 'Recipient added.' : 'Failed to add recipient'));
      if (res.success) {
        _addRecipientEmailController.clear();
        setState(() => _addingRecipient = false);
        await _loadRecipients();
      }
    } finally {
      if (!mounted) return;
      setState(() => _savingRecipient = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Send money'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transfer to another user', style: tt.titleLarge),
                  const SizedBox(height: AppSpacing.md),
                  SavedRecipientsSection(
                    loading: _loadingRecipients,
                    recipients: _recipients,
                    adding: _addingRecipient,
                    saving: _savingRecipient,
                    addEmailController: _addRecipientEmailController,
                    onTapRecipient: (email) {
                      _recipientEmailController.text = email;
                      _showMessage('Recipient selected.');
                    },
                    onToggleAdd: () => setState(() => _addingRecipient = !_addingRecipient),
                    onCancelAdd: () {
                      _addRecipientEmailController.clear();
                      setState(() => _addingRecipient = false);
                    },
                    onAdd: _handleAddRecipient,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _recipientEmailController,
                    decoration: InputDecoration(
                      labelText: 'Recipient email',
                      prefixIcon: Icon(Icons.alternate_email, color: cs.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.euro, color: cs.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.chat_bubble_outline, color: cs.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PaymentMethodSection(
                    loading: _loadingPaymentMethods,
                    methods: _paymentMethods,
                    selectedId: _selectedPaymentMethodId,
                    onSelect: (id) => setState(() => _selectedPaymentMethodId = id),
                    onManage: () async {
                      await context.push(AppRoutes.paymentMethods);
                      if (!mounted) return;
                      await _loadPaymentMethods();
                    },
                    onRefresh: _loadPaymentMethods,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sending ? null : _handleSend,
                      icon: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_sending ? 'Sending…' : 'Send'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SavedRecipientsSection extends StatelessWidget {
  final bool loading;
  final List<SavedRecipientModel> recipients;
  final bool adding;
  final bool saving;
  final TextEditingController addEmailController;
  final VoidCallback onToggleAdd;
  final VoidCallback onCancelAdd;
  final VoidCallback onAdd;
  final ValueChanged<String> onTapRecipient;

  const SavedRecipientsSection({
    super.key,
    required this.loading,
    required this.recipients,
    required this.adding,
    required this.saving,
    required this.addEmailController,
    required this.onToggleAdd,
    required this.onCancelAdd,
    required this.onAdd,
    required this.onTapRecipient,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Saved recipients', style: tt.titleMedium)),
              TextButton.icon(
                onPressed: onToggleAdd,
                icon: Icon(adding ? Icons.close : Icons.person_add_alt_1, color: cs.primary),
                label: Text(adding ? 'Close' : 'Add recipient', style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading) ...[
            LinearProgressIndicator(minHeight: 2, color: cs.primary, backgroundColor: cs.surfaceContainerHighest),
            const SizedBox(height: AppSpacing.md),
          ] else if (recipients.isEmpty) ...[
            Text('No saved recipients yet.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.md),
          ] else ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: recipients
                  .map(
                    (r) => InputChip(
                      label: Text(
                        r.recipientFullName?.isNotEmpty == true
                            ? '${r.recipientFullName} • ${r.recipientEmail}'
                            : r.recipientEmail,
                        overflow: TextOverflow.ellipsis,
                      ),
                      avatar: Icon(Icons.person_outline, color: cs.onSurfaceVariant, size: 18),
                      onPressed: () => onTapRecipient(r.recipientEmail),
                      labelStyle: TextStyle(color: cs.onSurface),
                      backgroundColor: cs.surfaceContainerHighest,
                      shape: StadiumBorder(side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45))),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: adding
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: addEmailController,
                        decoration: InputDecoration(
                          labelText: 'Recipient email',
                          prefixIcon: Icon(Icons.alternate_email, color: cs.onSurfaceVariant),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onAdd(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: saving ? null : onAdd,
                              icon: saving
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                                    )
                                  : const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: saving ? null : onCancelAdd,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class PaymentMethodSection extends StatelessWidget {
  final bool loading;
  final List<PaymentMethodModel> methods;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onManage;
  final VoidCallback onRefresh;

  const PaymentMethodSection({
    super.key,
    required this.loading,
    required this.methods,
    required this.selectedId,
    required this.onSelect,
    required this.onManage,
    required this.onRefresh,
  });

  IconData _brandIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      case 'visa':
      default:
        return Icons.credit_card;
    }
  }

  String _titleFor(PaymentMethodModel m) {
    final nick = (m.nickname ?? '').trim();
    if (nick.isNotEmpty) return nick;
    return '${m.brand.toUpperCase()} •••• ${m.last4}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final visible = methods.take(3).toList();
    final hasMore = methods.length > visible.length;

    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Payment method', style: tt.titleMedium)),
              IconButton(
                tooltip: 'Refresh',
                onPressed: loading ? null : onRefresh,
                icon: Icon(Icons.refresh, color: cs.primary),
              ),
              TextButton.icon(
                onPressed: onManage,
                icon: Icon(Icons.settings_outlined, color: cs.primary),
                label: Text('Manage', style: TextStyle(color: cs.primary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (loading)
            LinearProgressIndicator(minHeight: 2, color: cs.primary, backgroundColor: cs.surfaceContainerHighest)
          else if (methods.isEmpty)
            Text('No cards saved yet. Tap “Manage” to add one.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))
          else
            ...[
              for (final m in visible)
                RadioListTile<String>(
                  value: m.id,
                  groupValue: selectedId,
                  onChanged: (v) {
                    if (v == null) return;
                    onSelect(v);
                  },
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  secondary: Icon(_brandIcon(m.brand), color: cs.onSurfaceVariant),
                  title: Text(_titleFor(m), style: tt.bodyMedium),
                  subtitle: Text(
                    'Exp ${m.expMonth.toString().padLeft(2, '0')}/${m.expYear.toString().padLeft(2, '0')}${m.isDefault ? ' • Default' : ''}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              if (hasMore)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onManage,
                    child: Text('Show all (${methods.length})', style: TextStyle(color: cs.primary)),
                  ),
                ),
            ],
        ],
      ),
    );
  }
}
