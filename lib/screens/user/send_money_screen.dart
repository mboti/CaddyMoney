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
  final _amountController = TextEditingController();
  final _addRecipientEmailController = TextEditingController();
  final _noteController = TextEditingController();

  late final VoidCallback _amountListener;

  final RecipientService _recipientService = RecipientService();
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  final TransactionService _transactionService = TransactionService();

  bool _loadingRecipients = true;
  bool _addingRecipient = false;
  bool _savingRecipient = false;
  List<SavedRecipientModel> _recipients = const [];

  int _step = 0;
  String? _selectedRecipientEmail;
  SavedRecipientModel? _selectedRecipient;

  bool _transferCompleted = false;
  _TransferReceipt? _receipt;

  bool _loadingPaymentMethods = true;
  List<PaymentMethodModel> _paymentMethods = const [];
  String? _selectedPaymentMethodId;

  bool _sending = false;
  @override
  void initState() {
    super.initState();
    _amountListener = () {
      if (!mounted) return;
      // Rebuild so Step 2's CTA enables/disables immediately as the user types.
      if (_step == 1) setState(() {});
    };
    _amountController.addListener(_amountListener);
    _loadRecipients();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _amountController.removeListener(_amountListener);
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

  void _goToStep(int value) {
    if (_transferCompleted) return;
    setState(() => _step = value.clamp(0, 3));
  }

  bool get _canContinueFromStep1 => (_selectedRecipientEmail ?? '').trim().isNotEmpty;

  bool get _canContinueFromStep2 {
    final amount = _parseAmount(_amountController.text);
    return _canContinueFromStep1 && amount != null && amount > 0;
  }

  bool get _canContinueFromStep3 => _canContinueFromStep2 && _selectedPaymentMethodId != null;

  double? _parseAmount(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }

  Future<void> _handleSend() async {
    if (_sending) return;

    final recipientEmail = (_selectedRecipientEmail ?? '').trim();
    final amount = _parseAmount(_amountController.text);

    if (recipientEmail.isEmpty) {
      _showMessage('Please select a recipient.');
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

      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      final res = await _transactionService.transferUserToUser(
        receiverUserId: receiverId,
        amount: amount,
        note: note,
        paymentMethodId: _selectedPaymentMethodId,
      );

      if (!mounted) return;
      if (!res.success) {
        _showMessage(res.error ?? 'Transfer failed');
        return;
      }

      final pm = _paymentMethods.where((m) => m.id == _selectedPaymentMethodId).cast<PaymentMethodModel?>().firstOrNull;
      setState(() {
        _transferCompleted = true;
        _step = 3;
        _receipt = _TransferReceipt(
          recipientEmail: recipientEmail,
          recipientName: _selectedRecipient?.recipientFullName,
          amount: amount,
          note: note,
          paymentMethodTitle: pm == null ? null : _PaymentMethodSectionSupport.titleFor(pm),
          transactionReference: res.transactionReference,
        );
      });

      _amountController.clear();
      _noteController.clear();
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
        final newlyAddedEmail = _addRecipientEmailController.text.trim();
        _addRecipientEmailController.clear();
        setState(() {
          _addingRecipient = false;
          if (newlyAddedEmail.isNotEmpty) {
            _selectedRecipientEmail = newlyAddedEmail;
          }
        });
        await _loadRecipients();
        if (!mounted) return;
        final matched = _recipients.where((r) => r.recipientEmail.toLowerCase() == newlyAddedEmail.toLowerCase()).cast<SavedRecipientModel?>().firstOrNull;
        if (matched != null) {
          setState(() => _selectedRecipient = matched);
        }
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

    final title = _transferCompleted ? 'Transfer complete' : 'Send money';
    return PopScope(
      canPop: !_transferCompleted,
      onPopInvoked: (didPop) {
        if (_transferCompleted && mounted) context.go(AppRoutes.userHome);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_transferCompleted) {
                context.go(AppRoutes.userHome);
                return;
              }
              context.pop();
            },
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
                    StepHeader(
                      step: _step,
                      locked: _transferCompleted,
                      onTapStep: _goToStep,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_transferCompleted) ...[
                      TransferSuccessPanel(receipt: _receipt),
                    ] else ...[
                      if (_step == 0)
                        Step1Recipient(
                          titleStyle: tt.titleLarge,
                          loadingRecipients: _loadingRecipients,
                          recipients: _recipients,
                          addingRecipient: _addingRecipient,
                          savingRecipient: _savingRecipient,
                          addEmailController: _addRecipientEmailController,
                          selectedRecipientEmail: _selectedRecipientEmail,
                          onTapRecipient: (r) {
                            setState(() {
                              _selectedRecipientEmail = r.recipientEmail;
                              _selectedRecipient = r;
                            });
                          },
                          onToggleAdd: () => setState(() => _addingRecipient = !_addingRecipient),
                          onCancelAdd: () {
                            _addRecipientEmailController.clear();
                            setState(() => _addingRecipient = false);
                          },
                          onAdd: _handleAddRecipient,
                          onContinue: _canContinueFromStep1 ? () => _goToStep(1) : null,
                        ),
                      if (_step == 1)
                        Step2Details(
                          recipient: _selectedRecipient,
                          recipientEmail: _selectedRecipientEmail,
                          amountController: _amountController,
                          noteController: _noteController,
                          onBack: () => _goToStep(0),
                          onContinue: _canContinueFromStep2 ? () => _goToStep(2) : null,
                        ),
                      if (_step == 2)
                        Step3Payment(
                          loadingPaymentMethods: _loadingPaymentMethods,
                          paymentMethods: _paymentMethods,
                          selectedPaymentMethodId: _selectedPaymentMethodId,
                          onSelectPaymentMethod: (id) => setState(() => _selectedPaymentMethodId = id),
                          onManage: () async {
                            await context.push(AppRoutes.paymentMethods);
                            if (!mounted) return;
                            await _loadPaymentMethods();
                          },
                          onRefresh: _loadPaymentMethods,
                          onBack: () => _goToStep(1),
                          onContinue: _canContinueFromStep3 ? () => _goToStep(3) : null,
                        ),
                      if (_step == 3)
                        Step4Review(
                          recipient: _selectedRecipient,
                          recipientEmail: _selectedRecipientEmail,
                          amount: _parseAmount(_amountController.text),
                          note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                          paymentMethod: _paymentMethods.where((m) => m.id == _selectedPaymentMethodId).cast<PaymentMethodModel?>().firstOrNull,
                          sending: _sending,
                          onBack: () => _goToStep(2),
                          onSend: _handleSend,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TransferReceipt {
  final String recipientEmail;
  final String? recipientName;
  final double amount;
  final String? note;
  final String? paymentMethodTitle;
  final String? transactionReference;

  const _TransferReceipt({
    required this.recipientEmail,
    required this.recipientName,
    required this.amount,
    required this.note,
    required this.paymentMethodTitle,
    required this.transactionReference,
  });
}

class StepHeader extends StatelessWidget {
  final int step;
  final bool locked;
  final ValueChanged<int> onTapStep;

  const StepHeader({super.key, required this.step, required this.locked, required this.onTapStep});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StepPill(
            index: 0,
            current: step,
            locked: locked,
            title: 'Recipient',
            onTap: () => onTapStep(0),
          ),
          const _StepDivider(),
          _StepPill(
            index: 1,
            current: step,
            locked: locked,
            title: 'Details',
            onTap: () => onTapStep(1),
          ),
          const _StepDivider(),
          _StepPill(
            index: 2,
            current: step,
            locked: locked,
            title: 'Payment',
            onTap: () => onTapStep(2),
          ),
          const _StepDivider(),
          _StepPill(
            index: 3,
            current: step,
            locked: locked,
            title: 'Review',
            onTap: () => onTapStep(3),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (locked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('Locked', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
            ),
        ],
      ),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      color: cs.outlineVariant.withValues(alpha: 0.35),
    );
  }
}

class _StepPill extends StatelessWidget {
  final int index;
  final int current;
  final bool locked;
  final String title;
  final VoidCallback onTap;

  const _StepPill({required this.index, required this.current, required this.locked, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = index == current;
    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : cs.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? cs.onPrimaryContainer : cs.onSurface,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class Step1Recipient extends StatelessWidget {
  final TextStyle? titleStyle;
  final bool loadingRecipients;
  final List<SavedRecipientModel> recipients;
  final bool addingRecipient;
  final bool savingRecipient;
  final TextEditingController addEmailController;
  final String? selectedRecipientEmail;
  final ValueChanged<SavedRecipientModel> onTapRecipient;
  final VoidCallback onToggleAdd;
  final VoidCallback onCancelAdd;
  final VoidCallback onAdd;
  final VoidCallback? onContinue;

  const Step1Recipient({
    super.key,
    required this.titleStyle,
    required this.loadingRecipients,
    required this.recipients,
    required this.addingRecipient,
    required this.savingRecipient,
    required this.addEmailController,
    required this.selectedRecipientEmail,
    required this.onTapRecipient,
    required this.onToggleAdd,
    required this.onCancelAdd,
    required this.onAdd,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transfer to another user', style: titleStyle),
        const SizedBox(height: AppSpacing.md),
        SavedRecipientsSection(
          loading: loadingRecipients,
          recipients: recipients,
          adding: addingRecipient,
          saving: savingRecipient,
          addEmailController: addEmailController,
          selectedEmail: selectedRecipientEmail,
          onTapRecipient: onTapRecipient,
          onToggleAdd: onToggleAdd,
          onCancelAdd: onCancelAdd,
          onAdd: onAdd,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward),
            label: Text('Continue', style: tt.labelLarge),
          ),
        ),
      ],
    );
  }
}

class Step2Details extends StatelessWidget {
  final SavedRecipientModel? recipient;
  final String? recipientEmail;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final VoidCallback onBack;
  final VoidCallback? onContinue;

  const Step2Details({
    super.key,
    required this.recipient,
    required this.recipientEmail,
    required this.amountController,
    required this.noteController,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final email = (recipientEmail ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.person, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipient?.recipientFullName?.trim().isNotEmpty == true ? recipient!.recipientFullName!.trim() : 'Recipient', style: tt.titleMedium),
                    const SizedBox(height: 2),
                    Text(email, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: amountController,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixIcon: Icon(Icons.euro, color: cs.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            prefixIcon: Icon(Icons.chat_bubble_outline, color: cs.onSurfaceVariant),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          maxLines: 2,
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Confirm amount'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Step3Payment extends StatelessWidget {
  final bool loadingPaymentMethods;
  final List<PaymentMethodModel> paymentMethods;
  final String? selectedPaymentMethodId;
  final ValueChanged<String> onSelectPaymentMethod;
  final VoidCallback onManage;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback? onContinue;

  const Step3Payment({
    super.key,
    required this.loadingPaymentMethods,
    required this.paymentMethods,
    required this.selectedPaymentMethodId,
    required this.onSelectPaymentMethod,
    required this.onManage,
    required this.onRefresh,
    required this.onBack,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PaymentMethodSection(
          loading: loadingPaymentMethods,
          methods: paymentMethods,
          selectedId: selectedPaymentMethodId,
          onSelect: onSelectPaymentMethod,
          onManage: onManage,
          onRefresh: onRefresh,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Step4Review extends StatelessWidget {
  final SavedRecipientModel? recipient;
  final String? recipientEmail;
  final double? amount;
  final String? note;
  final PaymentMethodModel? paymentMethod;
  final bool sending;
  final VoidCallback onBack;
  final VoidCallback onSend;

  const Step4Review({
    super.key,
    required this.recipient,
    required this.recipientEmail,
    required this.amount,
    required this.note,
    required this.paymentMethod,
    required this.sending,
    required this.onBack,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final email = (recipientEmail ?? '').trim();
    final displayName = recipient?.recipientFullName?.trim().isNotEmpty == true ? recipient!.recipientFullName!.trim() : null;
    final pmTitle = paymentMethod == null ? null : _PaymentMethodSectionSupport.titleFor(paymentMethod!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
              Text('Review transfer', style: tt.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _ReviewRow(label: 'Recipient', value: displayName == null ? email : '$displayName ($email)'),
              const SizedBox(height: AppSpacing.sm),
              _ReviewRow(label: 'Amount', value: amount == null ? '—' : '€ ${amount!.toStringAsFixed(2)}'),
              const SizedBox(height: AppSpacing.sm),
              _ReviewRow(label: 'Payment method', value: pmTitle ?? '—'),
              if (note?.trim().isNotEmpty == true) ...[
                const SizedBox(height: AppSpacing.sm),
                _ReviewRow(label: 'Note', value: note!.trim()),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: sending ? null : onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(sending ? 'Sending…' : 'Send'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 120, child: Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(value, style: tt.bodyMedium, softWrap: true)),
      ],
    );
  }
}

class TransferSuccessPanel extends StatelessWidget {
  final _TransferReceipt? receipt;
  const TransferSuccessPanel({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = receipt;
    final recipientLabel = (r?.recipientName?.trim().isNotEmpty == true)
        ? r!.recipientName!.trim()
        : (r?.recipientEmail ?? '').trim();
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(14)),
                child: Icon(Icons.check_circle, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Success', style: tt.titleLarge),
                    const SizedBox(height: 2),
                    Text('The money has been sent to $recipientLabel', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReviewRow(label: 'Recipient', value: recipientLabel),
          const SizedBox(height: AppSpacing.sm),
          _ReviewRow(label: 'Amount', value: r == null ? '—' : '€ ${r.amount.toStringAsFixed(2)}'),
          const SizedBox(height: AppSpacing.sm),
          _ReviewRow(label: 'Payment method', value: r?.paymentMethodTitle ?? '—'),
          if (r?.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReviewRow(label: 'Note', value: r!.note!.trim()),
          ],
          if (r?.transactionReference?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReviewRow(label: 'Reference', value: r!.transactionReference!.trim()),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(
            'For security, you cannot return to the send flow once a transfer is completed.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
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
  final String? selectedEmail;
  final ValueChanged<SavedRecipientModel> onTapRecipient;

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
    required this.selectedEmail,
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
                    (r) {
                      final isSelected = (selectedEmail ?? '').trim().isNotEmpty && r.recipientEmail.toLowerCase() == selectedEmail!.trim().toLowerCase();
                      return InputChip(
                        label: Text(
                          r.recipientFullName?.isNotEmpty == true
                              ? '${r.recipientFullName} • ${r.recipientEmail}'
                              : r.recipientEmail,
                          overflow: TextOverflow.ellipsis,
                        ),
                        avatar: Icon(
                          isSelected ? Icons.person : Icons.person_outline,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () => onTapRecipient(r),
                        labelStyle: TextStyle(
                          color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        ),
                        backgroundColor: isSelected ? cs.primaryContainer : cs.surfaceContainerHighest,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.45),
                            width: isSelected ? 1.2 : 1,
                          ),
                        ),
                      );
                    },
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

  String _titleFor(PaymentMethodModel m) => _PaymentMethodSectionSupport.titleFor(m);

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

class _PaymentMethodSectionSupport {
  static String titleFor(PaymentMethodModel m) {
    final nick = (m.nickname ?? '').trim();
    if (nick.isNotEmpty) return nick;
    return '${m.brand.toUpperCase()} •••• ${m.last4}';
  }
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
