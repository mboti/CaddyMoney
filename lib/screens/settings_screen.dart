import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:caddymoney/providers/auth_provider.dart';
import 'package:caddymoney/providers/language_provider.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/core/constants/app_constants.dart';
import 'package:caddymoney/core/utils/app_localizations_temp.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: AppSpacing.paddingMd,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.fullName,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  user.email,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: Text(
                                    user.role.displayName,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.language, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.language,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        DropdownButton<String>(
                          value: languageProvider.languageCode,
                          underline: const SizedBox.shrink(),
                          items: [
                            const DropdownMenuItem(value: 'fr', child: Text('Français')),
                            const DropdownMenuItem(value: 'en', child: Text('English')),
                            const DropdownMenuItem(value: 'es', child: Text('Español')),
                            const DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                            const DropdownMenuItem(value: 'it', child: Text('Italiano')),
                            const DropdownMenuItem(value: 'ar', child: Text('العربية')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              languageProvider.setLanguage(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        l10n.version,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      '1.0.0',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (user != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await authProvider.signOut();
                      if (context.mounted) {
                        context.go('/role-selection');
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.signOut),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
