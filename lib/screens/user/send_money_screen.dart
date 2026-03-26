import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:caddymoney/models/saved_recipient_model.dart';
import 'package:caddymoney/services/recipient_service.dart';
import 'package:caddymoney/theme.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _recipientEmailController = TextEditingController();
  final _amountController = TextEditingController();
  final _addRecipientEmailController = TextEditingController();

  final RecipientService _recipientService = RecipientService();

  bool _loadingRecipients = true;
  bool _addingRecipient = false;
  bool _savingRecipient = false;
  List<SavedRecipientModel> _recipients = const [];

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _recipientEmailController.dispose();
    _amountController.dispose();
    _addRecipientEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    setState(() => _loadingRecipients = true);
    try {
      final list = await _recipientService.listMyRecipients();
      if (!mounted) return;
      setState(() => _recipients = list);
    } finally {
      if (!mounted) return;
      setState(() => _loadingRecipients = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
        child: Padding(
          padding: AppSpacing.paddingLg,
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
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon: send money flow')),
                    );
                  },
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Send'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Note: This screen is wired for routing; the transfer RPC integration can be connected next.',
                style: tt.bodySmall,
              ),
            ],
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
