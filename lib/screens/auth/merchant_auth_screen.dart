import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:caddymoney/providers/auth_provider.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/core/theme/app_colors.dart';
import 'package:caddymoney/core/constants/app_constants.dart';
import 'package:caddymoney/core/utils/app_localizations_temp.dart';
import 'package:caddymoney/core/enums/app_role.dart';

class MerchantAuthScreen extends StatefulWidget {
  const MerchantAuthScreen({super.key});

  @override
  State<MerchantAuthScreen> createState() => _MerchantAuthScreenState();
}

class _CategoryMultiSelectField extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const _CategoryMultiSelectField({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Categories', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
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
        ),
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'Select at least one category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.error),
            ),
          ),
      ],
    );
  }
}

class _MerchantAuthScreenState extends State<MerchantAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isSignIn && _selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one category.')));
      return;
    }

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isSignIn) {
      success = await authProvider.signInForRole(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        requiredRole: AppRole.merchant,
      );
    } else {
      success = await authProvider.signUpMerchant(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        businessName: _businessNameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isNotEmpty ? _addressLine2Controller.text.trim() : null,
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        countryName: _countryController.text.trim(),
        categories: _selectedCategories.toList(),
      );
    }

    if (success && mounted) {
      // Router will redirect merchants without full access to onboarding.
      context.go('/merchant-dashboard');
      return;
    }

    if (!mounted) return;
    final error = authProvider.error ?? 'Authentication failed';
    final isEmailNotConfirmed = error.toLowerCase().contains('email not confirmed');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEmailNotConfirmed ? 'Email not confirmed. Please check your inbox.' : error),
        action: isEmailNotConfirmed
            ? SnackBarAction(
                label: 'Resend',
                onPressed: () async {
                  final ok = await context.read<AuthProvider>().resendSignupConfirmationEmail(_emailController.text);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Confirmation email sent.' : (context.read<AuthProvider>().error ?? 'Failed to resend'))),
                  );
                },
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _isSignIn ? l10n.merchantRole : 'Register Merchant',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (!_isSignIn) ...[
                  TextFormField(
                    controller: _businessNameController,
                    decoration: InputDecoration(
                      labelText: l10n.businessName,
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return l10n.requiredField;
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return l10n.requiredField;
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return l10n.requiredField;
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _CategoryMultiSelectField(
                    selected: _selectedCategories,
                    onChanged: (next) => setState(() {
                      _selectedCategories
                        ..clear()
                        ..addAll(next);
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressLine1Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address line',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressLine2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Address complement',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Postal code',
                            prefixIcon: Icon(Icons.local_post_office_outlined),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      helperText: 'Use full name (e.g., France, United States)',
                      prefixIcon: Icon(Icons.public_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredField : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.requiredField;
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: l10n.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.requiredField;
                    }
                    if (value.length < 8) {
                      return l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                if (!_isSignIn) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleSubmit,
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignIn ? l10n.signIn : l10n.signUp),
                ),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isSignIn = !_isSignIn),
                    child: Text(
                      _isSignIn ? l10n.dontHaveAccount : l10n.alreadyHaveAccount,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
                if (authProvider.error != null && authProvider.error!.toLowerCase().contains('email not confirmed')) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Center(
                    child: TextButton(
                      onPressed: authProvider.isLoading
                          ? null
                          : () async {
                              final ok = await context.read<AuthProvider>().resendSignupConfirmationEmail(_emailController.text);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok ? 'Confirmation email sent.' : (context.read<AuthProvider>().error ?? 'Failed to resend'))),
                              );
                            },
                      child: const Text('Resend confirmation email', style: TextStyle(color: AppColors.primary)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
