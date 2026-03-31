import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_selector/file_selector.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/core/constants/app_constants.dart';
import 'package:caddymoney/core/enums/merchant_status.dart';
import 'package:caddymoney/providers/auth_provider.dart';
import 'package:caddymoney/services/merchant_service.dart';

class MerchantOnboardingKycScreen extends StatefulWidget {
  const MerchantOnboardingKycScreen({super.key});

  @override
  State<MerchantOnboardingKycScreen> createState() => _MerchantOnboardingKycScreenState();
}

class _MerchantOnboardingKycScreenState extends State<MerchantOnboardingKycScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantService = MerchantService();

  final _businessNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final _businessTypeController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _vatNumberController = TextEditingController();

  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();

  final _ibanController = TextEditingController();
  final _accountHolderController = TextEditingController();

  final _supportAddressController = TextEditingController();

  bool _loading = false;
  bool _smsVerified = false;
  DateTime? _dateOfBirth;
  Set<String> _categories = {};

  XFile? _idDoc;
  XFile? _proofOfAddress;
  XFile? _registrationDoc;

  bool _prefillLoaded = false;

  static const _prefsKey = 'merchant_kyc_draft_v1';

  @override
  void initState() {
    super.initState();
    _loadPrefill();

    for (final c in [
      _businessTypeController,
      _registrationNumberController,
      _vatNumberController,
      _addressLine1Controller,
      _addressLine2Controller,
      _cityController,
      _postalCodeController,
      _countryController,
      _dobController,
      _nationalityController,
      _ibanController,
      _accountHolderController,
      _supportAddressController,
    ]) {
      c.addListener(_scheduleAutosave);
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _businessTypeController.dispose();
    _registrationNumberController.dispose();
    _vatNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _ibanController.dispose();
    _accountHolderController.dispose();
    _supportAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefill() async {
    final auth = context.read<AuthProvider>();

    // Load merchant record (fresh) to prefill the UI.
    await auth.refreshMerchant();
    final m = auth.currentMerchant;
    final u = auth.currentUser;

    if (m != null) {
      _businessNameController.text = m.businessName;
      _firstNameController.text = m.ownerFirstName ?? (u?.fullName.split(' ').firstOrNull ?? '');
      _lastNameController.text = m.ownerLastName ?? ((u?.fullName ?? '').split(' ').skip(1).join(' '));
      _phoneController.text = m.businessPhone ?? '';
      _emailController.text = m.businessEmail;

      _addressLine1Controller.text = m.addressLine1 ?? '';
      _addressLine2Controller.text = m.addressLine2 ?? '';
      _cityController.text = m.city ?? '';
      _postalCodeController.text = m.postalCode ?? '';
      _countryController.text = m.countryName ?? (m.countryCode ?? '');

      _categories = {...m.categories};
    }

    // Then apply any local autosave draft over it.
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = MerchantKycDraft.decode(raw);
        _businessTypeController.text = map.businessType ?? _businessTypeController.text;
        _registrationNumberController.text = map.registrationNumber ?? _registrationNumberController.text;
        _vatNumberController.text = map.vatNumber ?? _vatNumberController.text;
        _nationalityController.text = map.nationality ?? _nationalityController.text;
        _ibanController.text = map.iban ?? _ibanController.text;
        _accountHolderController.text = map.accountHolderName ?? _accountHolderController.text;
        _supportAddressController.text = map.customerSupportAddress ?? _supportAddressController.text;
        if (map.categories.isNotEmpty) _categories = {...map.categories};
        if (map.dateOfBirthIso != null) {
          _dateOfBirth = DateTime.tryParse(map.dateOfBirthIso!);
          if (_dateOfBirth != null) _dobController.text = _formatDate(_dateOfBirth!);
        }
        _smsVerified = map.smsVerified ?? _smsVerified;
      }
    } catch (e) {
      debugPrint('Failed to load merchant KYC draft: $e');
    }

    if (mounted) setState(() => _prefillLoaded = true);
  }

  DateTime? _tryParseDob() {
    final text = _dobController.text.trim();
    if (text.isEmpty) return null;

    // Expect: YYYY-MM-DD
    final parsed = DateTime.tryParse(text);
    return parsed;
  }

  String _formatDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isPrefilledController(TextEditingController c) => c.text.trim().isNotEmpty;

  InputDecoration _prefilledDecoration(BuildContext context, InputDecoration base) {
    final cs = Theme.of(context).colorScheme;
    return base.copyWith(
      filled: true,
      fillColor: cs.primaryContainer.withValues(alpha: 0.35),
    );
  }

  void _scheduleAutosave() {
    // Keep simple: save on each change.
    _autosave();
  }

  Future<void> _autosave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = MerchantKycDraft(
        businessType: _businessTypeController.text.trim().isEmpty ? null : _businessTypeController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim().isEmpty ? null : _registrationNumberController.text.trim(),
        vatNumber: _vatNumberController.text.trim().isEmpty ? null : _vatNumberController.text.trim(),
        dateOfBirthIso: _dateOfBirth?.toIso8601String(),
        nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
        iban: _ibanController.text.trim().isEmpty ? null : _ibanController.text.trim(),
        accountHolderName: _accountHolderController.text.trim().isEmpty ? null : _accountHolderController.text.trim(),
        customerSupportAddress: _supportAddressController.text.trim().isEmpty ? null : _supportAddressController.text.trim(),
        categories: _categories.toList(),
        smsVerified: _smsVerified,
      );
      await prefs.setString(_prefsKey, draft.encode());
    } catch (e) {
      debugPrint('Merchant KYC autosave failed: $e');
    }
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initial = _dateOfBirth ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year - 18, now.month, now.day),
    );
    if (picked == null) return;
    setState(() {
      _dateOfBirth = picked;
      _dobController.text = _formatDate(picked);
    });
    _autosave();
  }

  Future<XFile?> _pickDocument({required String label}) async {
    final group = XTypeGroup(label: label, extensions: const ['pdf', 'png', 'jpg', 'jpeg']);
    final file = await openFile(acceptedTypeGroups: [group]);
    return file;
  }

  bool _isFormCompleteForSubmit() {
    if (_businessTypeController.text.trim().isEmpty) return false;
    if (_registrationNumberController.text.trim().isEmpty) return false;
    if (_dateOfBirth == null) return false;
    if (_nationalityController.text.trim().isEmpty) return false;
    if (_ibanController.text.trim().isEmpty) return false;
    if (_accountHolderController.text.trim().isEmpty) return false;
    if (_supportAddressController.text.trim().isEmpty) return false;
    if (_categories.isEmpty) return false;
    if (_idDoc == null || _proofOfAddress == null || _registrationDoc == null) return false;
    if (!_smsVerified) return false;
    return true;
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormCompleteForSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields and documents.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Upload documents first.
      final idPath = await _merchantService.uploadMerchantDocument(docType: 'id_document', file: _idDoc!);
      final proofPath = await _merchantService.uploadMerchantDocument(docType: 'proof_of_address', file: _proofOfAddress!);
      final regPath = await _merchantService.uploadMerchantDocument(docType: 'business_registration', file: _registrationDoc!);

      if (idPath == null || proofPath == null || regPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again or contact support.')),
        );
        return;
      }

      final ok = await _merchantService.updateMyMerchantKyc(
        businessType: _businessTypeController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        vatNumber: _vatNumberController.text.trim().isEmpty ? null : _vatNumberController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        nationality: _nationalityController.text.trim(),
        iban: _ibanController.text.trim(),
        accountHolderName: _accountHolderController.text.trim(),
        customerSupportAddress: _supportAddressController.text.trim(),
        categories: _categories.toList(),
        smsVerified: _smsVerified,
        idDocumentPath: idPath,
        proofOfAddressPath: proofPath,
        businessRegistrationDocPath: regPath,
      );

      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save your profile. Please try again.')),
        );
        return;
      }

      await context.read<AuthProvider>().refreshMerchant();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile submitted. Awaiting verification.')),
      );
      setState(() {});
    } catch (e) {
      debugPrint('Merchant KYC submit failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final merchant = auth.currentMerchant;
    final isApproved = merchant?.status == MerchantStatus.approved;
    final profileCompleted = merchant?.profileCompleted == true;

    final progress = isApproved
        ? 1.0
        : profileCompleted
            ? 0.85
            : 0.45;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/role-selection')),
        title: const Text('Merchant Verification'),
      ),
      body: SafeArea(
        child: !_prefillLoaded
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusHeader(progress: progress, statusText: _statusText(merchant)),
                    const SizedBox(height: AppSpacing.lg),

                    if (isApproved) ...[
                      _VerifiedPanel(onGoDashboard: () => context.go('/merchant-dashboard')),
                      const SizedBox(height: AppSpacing.lg),
                    ] else ...[
                      _BlockedPanel(
                        title: profileCompleted ? 'Profile submitted' : 'Profile incomplete',
                        message: profileCompleted
                            ? 'Thanks — we are reviewing your information. You’ll get access once verified.'
                            : 'To protect the platform, you must complete verification before using the app.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle(icon: Icons.business_outlined, title: '1. Business information'),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _businessNameController,
                            enabled: false,
                            decoration: _prefilledDecoration(
                              context,
                              const InputDecoration(labelText: 'Legal business name', prefixIcon: Icon(Icons.business_outlined)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _businessTypeController,
                            decoration: const InputDecoration(labelText: 'Business type (LLC, Corporation, etc.)', prefixIcon: Icon(Icons.apartment_outlined)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _PrefilledAddressPanel(
                            line1: _addressLine1Controller,
                            line2: _addressLine2Controller,
                            city: _cityController,
                            postalCode: _postalCodeController,
                            country: _countryController,
                            prefilledDecoration: (d) => _prefilledDecoration(context, d),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _registrationNumberController,
                            decoration: const InputDecoration(labelText: 'Business registration number (e.g., SIRET)', prefixIcon: Icon(Icons.badge_outlined)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _vatNumberController,
                            decoration: const InputDecoration(labelText: 'VAT number (optional)', prefixIcon: Icon(Icons.confirmation_number_outlined)),
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          _SectionTitle(icon: Icons.person_outline, title: '2. Seller identity'),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  enabled: false,
                                  decoration: _prefilledDecoration(
                                    context,
                                    const InputDecoration(labelText: 'First name', prefixIcon: Icon(Icons.person_outline)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  enabled: false,
                                  decoration: _prefilledDecoration(
                                    context,
                                    const InputDecoration(labelText: 'Last name', prefixIcon: Icon(Icons.person_outline)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Date of birth',
                              prefixIcon: const Icon(Icons.cake_outlined),
                              suffixIcon: IconButton(icon: const Icon(Icons.calendar_month_outlined), onPressed: _pickDateOfBirth),
                            ),
                            validator: (_) => _dateOfBirth == null ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _nationalityController,
                            decoration: const InputDecoration(labelText: 'Nationality', prefixIcon: Icon(Icons.flag_outlined)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DocumentPickerRow(
                            title: 'Identity document (ID or passport)',
                            value: _idDoc?.name,
                            onPick: () async {
                              final f = await _pickDocument(label: 'Identity document');
                              if (f == null) return;
                              setState(() => _idDoc = f);
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          _SectionTitle(icon: Icons.account_balance_outlined, title: '3. Banking information'),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _ibanController,
                            decoration: const InputDecoration(labelText: 'IBAN', prefixIcon: Icon(Icons.account_balance_outlined)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _accountHolderController,
                            decoration: const InputDecoration(labelText: 'Account holder name', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          _SectionTitle(icon: Icons.category_outlined, title: '4. Business activity'),
                          const SizedBox(height: AppSpacing.md),
                          _CategoryMultiSelect(
                            selected: _categories,
                            onChanged: (next) {
                              setState(() => _categories = next);
                              _autosave();
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          _SectionTitle(icon: Icons.support_agent_outlined, title: '5. Contact & customer support'),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _phoneController,
                            enabled: false,
                            decoration: _prefilledDecoration(
                              context,
                              const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _emailController,
                            enabled: false,
                            decoration: _prefilledDecoration(
                              context,
                              const InputDecoration(labelText: 'Professional email', prefixIcon: Icon(Icons.email_outlined)),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _supportAddressController,
                            decoration: const InputDecoration(labelText: 'Customer contact address', prefixIcon: Icon(Icons.location_on_outlined)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          _SectionTitle(icon: Icons.verified_outlined, title: '6. Verification & compliance'),
                          const SizedBox(height: AppSpacing.md),
                          _DocumentPickerRow(
                            title: 'Proof of address (utility bill)',
                            value: _proofOfAddress?.name,
                            onPick: () async {
                              final f = await _pickDocument(label: 'Proof of address');
                              if (f == null) return;
                              setState(() => _proofOfAddress = f);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _DocumentPickerRow(
                            title: 'Business registration document (e.g., Kbis)',
                            value: _registrationDoc?.name,
                            onPick: () async {
                              final f = await _pickDocument(label: 'Business registration');
                              if (f == null) return;
                              setState(() => _registrationDoc = f);
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _SmsVerificationTile(
                            isVerified: _smsVerified,
                            onVerify: () async {
                              // Placeholder: here you would trigger SMS OTP.
                              // For now: allow manual "verify" to keep the flow testable.
                              setState(() => _smsVerified = true);
                              _autosave();
                            },
                          ),

                          const SizedBox(height: AppSpacing.xl),
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _submit,
                            icon: _loading
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.lock_open_outlined, color: Colors.white),
                            label: const Text('Submit for verification', style: TextStyle(color: Colors.white)),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Access unlocks only after verification.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _statusText(merchant) {
    if (merchant == null) return 'Profile incomplete (blocked)';
    if (merchant.status == MerchantStatus.approved) return 'Profile verified (full access)';
    if (merchant.profileCompleted == true) return 'Profile submitted (review in progress)';
    return 'Profile incomplete (blocked)';
  }
}

class _StatusHeader extends StatelessWidget {
  final double progress;
  final String statusText;

  const _StatusHeader({required this.progress, required this.statusText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: cs.surfaceContainerHighest,
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: cs.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: cs.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedPanel extends StatelessWidget {
  final String title;
  final String message;

  const _BlockedPanel({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: cs.errorContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: cs.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedPanel extends StatelessWidget {
  final VoidCallback onGoDashboard;

  const _VerifiedPanel({required this.onGoDashboard});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        color: cs.primaryContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_outlined, color: cs.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'You’re verified. Full access is unlocked.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          FilledButton(
            onPressed: onGoDashboard,
            child: const Text('Open dashboard'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _DocumentPickerRow extends StatelessWidget {
  final String title;
  final String? value;
  final VoidCallback onPick;

  const _DocumentPickerRow({required this.title, required this.value, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        color: cs.surface,
      ),
      child: Row(
        children: [
          Icon(Icons.upload_file_outlined, color: cs.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value ?? 'No file selected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton.tonal(onPressed: onPick, child: const Text('Choose')),
        ],
      ),
    );
  }
}

class _SmsVerificationTile extends StatelessWidget {
  final bool isVerified;
  final VoidCallback onVerify;

  const _SmsVerificationTile({required this.isVerified, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(isVerified ? Icons.verified_outlined : Icons.sms_outlined, color: isVerified ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SMS verification', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isVerified ? 'Verified' : 'Required to submit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          FilledButton.tonal(onPressed: isVerified ? null : onVerify, child: Text(isVerified ? 'Done' : 'Verify')),
        ],
      ),
    );
  }
}

class _CategoryMultiSelect extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _CategoryMultiSelect({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.businessCategories.map((c) {
        final isSelected = selected.contains(c);
        return FilterChip(
          label: Text(c),
          selected: isSelected,
          selectedColor: cs.primaryContainer,
          checkmarkColor: cs.primary,
          onSelected: (v) {
            final next = {...selected};
            if (v) {
              next.add(c);
            } else {
              next.remove(c);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}

class _PrefilledAddressPanel extends StatelessWidget {
  final TextEditingController line1;
  final TextEditingController line2;
  final TextEditingController city;
  final TextEditingController postalCode;
  final TextEditingController country;
  final InputDecoration Function(InputDecoration) prefilledDecoration;

  const _PrefilledAddressPanel({
    required this.line1,
    required this.line2,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.prefilledDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: line1,
          enabled: false,
          decoration: prefilledDecoration(const InputDecoration(labelText: 'Registered address line', prefixIcon: Icon(Icons.location_on_outlined))),
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: line2,
          enabled: false,
          decoration: prefilledDecoration(const InputDecoration(labelText: 'Address complement', prefixIcon: Icon(Icons.location_on_outlined))),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: city,
                enabled: false,
                decoration: prefilledDecoration(const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined))),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                controller: postalCode,
                enabled: false,
                decoration: prefilledDecoration(const InputDecoration(labelText: 'Postal code', prefixIcon: Icon(Icons.local_post_office_outlined))),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: country,
          enabled: false,
          decoration: prefilledDecoration(const InputDecoration(labelText: 'Country', prefixIcon: Icon(Icons.public_outlined))),
        ),
      ],
    );
  }
}

class MerchantKycDraft {
  final String? businessType;
  final String? registrationNumber;
  final String? vatNumber;
  final String? dateOfBirthIso;
  final String? nationality;
  final String? iban;
  final String? accountHolderName;
  final String? customerSupportAddress;
  final List<String> categories;
  final bool? smsVerified;

  MerchantKycDraft({
    required this.businessType,
    required this.registrationNumber,
    required this.vatNumber,
    required this.dateOfBirthIso,
    required this.nationality,
    required this.iban,
    required this.accountHolderName,
    required this.customerSupportAddress,
    required this.categories,
    required this.smsVerified,
  });

  String encode() {
    return [
      businessType ?? '',
      registrationNumber ?? '',
      vatNumber ?? '',
      dateOfBirthIso ?? '',
      nationality ?? '',
      iban ?? '',
      accountHolderName ?? '',
      customerSupportAddress ?? '',
      categories.join('|'),
      (smsVerified == true) ? '1' : '0',
    ].join(';;');
  }

  static MerchantKycDraft decode(String raw) {
    final parts = raw.split(';;');
    String? pick(int i) => parts.length > i && parts[i].trim().isNotEmpty ? parts[i].trim() : null;

    final cats = pick(8)?.split('|').where((e) => e.trim().isNotEmpty).toList() ?? <String>[];
    final sms = (parts.length > 9 && parts[9] == '1');
    return MerchantKycDraft(
      businessType: pick(0),
      registrationNumber: pick(1),
      vatNumber: pick(2),
      dateOfBirthIso: pick(3),
      nationality: pick(4),
      iban: pick(5),
      accountHolderName: pick(6),
      customerSupportAddress: pick(7),
      categories: cats,
      smsVerified: sms,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
