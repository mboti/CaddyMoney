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

class _MerchantAuthScreenState extends State<MerchantAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedCategory;
  String? _selectedCountry;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

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
        ownerName: _ownerNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        businessCategory: _selectedCategory,
        address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
        country: _selectedCountry,
      );
    }

    if (success && mounted) {
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
                  TextFormField(
                    controller: _ownerNameController,
                    decoration: InputDecoration(
                      labelText: l10n.ownerName,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: l10n.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: l10n.category,
                      prefixIcon: const Icon(Icons.category_outlined),
                    ),
                    items: AppConstants.businessCategories.map((category) {
                      return DropdownMenuItem(value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: '${l10n.address} (${l10n.optional})',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: '${l10n.city} (${l10n.optional})',
                            prefixIcon: const Icon(Icons.location_city_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCountry,
                          decoration: InputDecoration(
                            labelText: '${l10n.country} (${l10n.optional})',
                          ),
                          items: ['FR', 'US', 'GB', 'DE', 'ES', 'IT'].map((country) {
                            return DropdownMenuItem(value: country, child: Text(country));
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedCountry = value),
                        ),
                      ),
                    ],
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
