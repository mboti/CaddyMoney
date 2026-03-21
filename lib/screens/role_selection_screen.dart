import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:caddymoney/theme.dart';
import 'package:caddymoney/core/utils/app_localizations_temp.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n.roleSelectionTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.roleSelectionSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              RoleOptionCard(
                icon: Icons.person_outline,
                title: l10n.userRole,
                subtitle: l10n.userRoleDesc,
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.push('/user-auth'),
              ),
              const SizedBox(height: AppSpacing.lg),
              RoleOptionCard(
                icon: Icons.store_outlined,
                title: l10n.merchantRole,
                subtitle: l10n.merchantRoleDesc,
                color: Theme.of(context).colorScheme.secondary,
                onTap: () => context.push('/merchant-auth'),
              ),
              const SizedBox(height: AppSpacing.lg),
              RoleOptionCard(
                icon: Icons.admin_panel_settings_outlined,
                title: l10n.adminRole,
                subtitle: l10n.adminRoleDesc,
                color: Theme.of(context).colorScheme.tertiary,
                onTap: () => context.push('/admin-login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const RoleOptionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: AppSpacing.paddingLg,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
