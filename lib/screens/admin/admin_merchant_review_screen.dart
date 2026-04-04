import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:caddymoney/core/constants/app_constants.dart';
import 'package:caddymoney/core/config/supabase_config.dart';
import 'package:caddymoney/models/merchant_model.dart';
import 'package:caddymoney/services/merchant_service.dart';
import 'package:caddymoney/theme.dart';

class AdminMerchantReviewArgs {
  final MerchantModel merchant;
  const AdminMerchantReviewArgs({required this.merchant});
}

class AdminMerchantReviewScreen extends StatefulWidget {
  final AdminMerchantReviewArgs args;
  const AdminMerchantReviewScreen({super.key, required this.args});

  @override
  State<AdminMerchantReviewScreen> createState() => _AdminMerchantReviewScreenState();
}

class _AdminMerchantReviewScreenState extends State<AdminMerchantReviewScreen> {
  final _service = MerchantService();
  bool _isBusy = false;

  MerchantModel get _m => widget.args.merchant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final m = _m;
    final owner = [m.ownerFirstName, m.ownerLastName].whereType<String>().where((e) => e.trim().isNotEmpty).join(' ');
    final categories = m.categories.isNotEmpty ? m.categories.join(', ') : (m.businessCategory ?? '—');
    final submitted = DateFormat.yMMMd().add_Hm().format(m.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant review'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.paddingLg,
                children: [
                  _HeaderCard(
                    businessName: m.businessName,
                    ownerName: owner.isNotEmpty ? owner : (m.ownerName ?? '—'),
                    statusText: m.status.toJson(),
                    submittedText: submitted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Business information',
                    icon: Icons.store_outlined,
                    children: [
                      _InfoLabelRow(label: 'Business name', value: m.businessName),
                      _InfoLabelRow(label: 'Business type', value: m.businessType ?? '—'),
                      _InfoLabelRow(label: 'Registration number', value: m.registrationNumber ?? '—'),
                      _InfoLabelRow(label: 'VAT number', value: m.vatNumber ?? '—'),
                      _InfoLabelRow(label: 'Email', value: m.businessEmail),
                      _InfoLabelRow(label: 'Phone', value: m.businessPhone ?? '—'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Address',
                    icon: Icons.location_on_outlined,
                    children: [
                      _InfoLabelRow(label: 'Address line 1', value: m.addressLine1 ?? '—'),
                      _InfoLabelRow(label: 'Address line 2', value: m.addressLine2?.trim().isNotEmpty == true ? m.addressLine2! : '—'),
                      _InfoLabelRow(label: 'City', value: m.city ?? '—'),
                      _InfoLabelRow(label: 'Postal code', value: m.postalCode ?? '—'),
                      _InfoLabelRow(label: 'Country', value: m.countryName ?? m.countryCode ?? '—'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Seller identity',
                    icon: Icons.badge_outlined,
                    children: [
                      _InfoLabelRow(label: 'Owner', value: owner.isNotEmpty ? owner : (m.ownerName ?? '—')),
                      _InfoLabelRow(label: 'Date of birth', value: m.dateOfBirth == null ? '—' : DateFormat.yMMMd().format(m.dateOfBirth!.toLocal())),
                      _InfoLabelRow(label: 'Nationality', value: m.nationality ?? '—'),
                      _DocumentLinkRow(
                        label: 'Identity document',
                        objectPath: m.idDocumentPath,
                        icon: Icons.credit_card_outlined,
                      ),
                      _DocumentLinkRow(
                        label: 'Proof of address',
                        objectPath: m.proofOfAddressPath,
                        icon: Icons.home_work_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Banking information',
                    icon: Icons.account_balance_outlined,
                    children: [
                      _InfoLabelRow(label: 'IBAN', value: m.iban ?? '—'),
                      _InfoLabelRow(label: 'Account holder name', value: m.accountHolderName ?? '—'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Business activity',
                    icon: Icons.category_outlined,
                    children: [
                      _InfoLabelRow(label: 'Categories', value: categories.isNotEmpty ? categories : '—'),
                      _LogoPreviewRow(label: 'Logo', objectPath: m.logoPath),
                      _DocumentLinkRow(
                        label: 'Business registration document',
                        objectPath: m.businessRegistrationDocPath,
                        icon: Icons.description_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: AppSpacing.paddingMd,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: scheme.outline),
                    ),
                    child: Text(
                      'Tip: document links are time-limited signed URLs. If a link expires, tap it again to generate a fresh one.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            _BottomDecisionBar(
              isBusy: _isBusy,
              onReject: _isBusy ? null : _onReject,
              onApprove: _isBusy ? null : _onApprove,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onApprove() async {
    setState(() => _isBusy = true);
    try {
      final res = await _service.decideMerchantReviewResult(merchantId: _m.id, decision: 'approve');
      if (!mounted) return;
      if (!res.ok) {
        final missing = res.missingFields;
        final msg = missing != null && missing.isNotEmpty
            ? 'Cannot approve: missing fields: ${missing.join(', ')}'
            : (res.error ?? 'Approval failed.');
        _showSnack(msg, isError: true);
        if (_looksLikeAuthExpired(res.error)) context.go('/admin-login');
        return;
      }

      final emailMsg = (res.emailSent == true)
          ? 'Approved. Email sent to merchant.'
          : (res.emailSkipped == true)
              ? 'Approved. Email skipped (email provider not configured).'
              : 'Approved.';
      _showSnack(emailMsg, isError: false);
      if (mounted) context.pop(true);
    } catch (e) {
      debugPrint('Admin merchant review approve failed: $e');
      if (mounted) _showSnack('Approval failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _onReject() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _ConfirmRejectSheet(businessName: _m.businessName),
    );
    if (confirmed != true) return;

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _RejectMerchantReasonSheet(businessName: _m.businessName),
    );
    final trimmed = (reason ?? '').trim();
    if (trimmed.isEmpty) return;

    setState(() => _isBusy = true);
    try {
      final res = await _service.decideMerchantReviewResult(merchantId: _m.id, decision: 'reject', reason: trimmed);
      if (!mounted) return;
      if (!res.ok) {
        _showSnack(res.error ?? 'Rejection failed.', isError: true);
        if (_looksLikeAuthExpired(res.error)) context.go('/admin-login');
        return;
      }

      final emailMsg = (res.emailSent == true)
          ? 'Rejected. Email sent to merchant.'
          : (res.emailSkipped == true)
              ? 'Rejected. Email skipped (email provider not configured).'
              : 'Rejected.';
      _showSnack(emailMsg, isError: false);
      if (mounted) context.pop(true);
    } catch (e) {
      debugPrint('Admin merchant review reject failed: $e');
      if (mounted) _showSnack('Rejection failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isError ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = isError ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _looksLikeAuthExpired(String? message) {
    final m = (message ?? '').toLowerCase();
    return m.contains('unauthorized') || m.contains('sign in again') || m.contains('session expired') || m.contains('not signed in');
  }
}

class _HeaderCard extends StatelessWidget {
  final String businessName;
  final String ownerName;
  final String statusText;
  final String submittedText;

  const _HeaderCard({
    required this.businessName,
    required this.ownerName,
    required this.statusText,
    required this.submittedText,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.surface, scheme.surfaceContainerHighest.withValues(alpha: 0.35)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            businessName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Owner: $ownerName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(icon: Icons.timelapse, text: submittedText),
              _MetaChip(icon: Icons.verified_outlined, text: statusText),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _InfoLabelRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoLabelRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentLinkRow extends StatefulWidget {
  final String label;
  final String? objectPath;
  final IconData icon;
  const _DocumentLinkRow({required this.label, required this.objectPath, required this.icon});

  @override
  State<_DocumentLinkRow> createState() => _DocumentLinkRowState();
}

class _DocumentLinkRowState extends State<_DocumentLinkRow> {
  bool _opening = false;

  String? _normalizeObjectPath({required String bucket, required String raw}) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    // If the DB already stored a signed URL (or public URL), don't treat it as an object key.
    final uri = Uri.tryParse(s);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) return s;

    var path = s;
    if (path.startsWith('/')) path = path.substring(1);

    // Common mistake: storing `bucket/objectKey` instead of `objectKey`.
    if (path.startsWith('$bucket/')) path = path.substring(bucket.length + 1);

    // If a full storage URL was stored, extract the object key part.
    // Examples:
    // - .../storage/v1/object/public/<bucket>/<objectKey>
    // - .../storage/v1/object/sign/<bucket>/<objectKey>?token=...
    if (path.contains('storage/v1/object/')) {
      final parsed = Uri.tryParse('https://dummy/$path');
      final segments = parsed?.pathSegments ?? const <String>[];
      final i = segments.indexWhere((e) => e == 'public' || e == 'sign');
      if (i != -1 && segments.length >= i + 2) {
        final bucketSeg = segments[i + 1];
        if (bucketSeg == bucket && segments.length > i + 2) {
          path = segments.sublist(i + 2).join('/');
        }
      }
    }

    return path.trim().isEmpty ? null : path;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = widget.objectPath;
    final hasDoc = (path ?? '').trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerLeft,
              child: hasDoc
                  ? TextButton.icon(
                      onPressed: _opening ? null : () => _openDoc(path!),
                      icon: _opening
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                            )
                          : Icon(widget.icon, size: 18, color: scheme.primary),
                      label: Text(
                        'Open',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary),
                      ),
                    )
                  : Text('—', style: Theme.of(context).textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDoc(String objectPath) async {
    setState(() => _opening = true);
    try {
      final bucket = AppConstants.kycStorageBucket;

      final normalized = _normalizeObjectPath(bucket: bucket, raw: objectPath);
      if (normalized == null) throw 'Missing document path.';

      // If it is already a URL, open it directly.
      final direct = Uri.tryParse(normalized);
      final isDirectUrl = direct != null && (direct.scheme == 'http' || direct.scheme == 'https');

      final url = isDirectUrl
          ? normalized
          : await SupabaseConfig.client.storage.from(bucket).createSignedUrl(normalized, 60 * 15);

      final uri = Uri.tryParse(url);
      if (uri == null) throw 'Invalid document URL.';

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'Could not open document link.';
    } on StorageException catch (e) {
      final bucket = AppConstants.kycStorageBucket;
      final normalized = _normalizeObjectPath(bucket: bucket, raw: objectPath);
      debugPrint('AdminMerchantReview: open document failed (storage). bucket=$bucket object=$normalized error=$e');

      // Storage RLS often returns 404 (not_found) for unauthorized reads.
      // As an admin, fall back to an Edge Function that verifies admin role and
      // uses the service role key to generate the signed URL.
      final status = e.statusCode?.toString();
      final isNotFound = status == '404' || e.message.toLowerCase().contains('not found');
      var attemptedFallback = false;
      if (isNotFound && normalized != null) {
        try {
          attemptedFallback = true;
          debugPrint('AdminMerchantReview: attempting Edge Function signed-url fallback...');
          final res = await SupabaseConfig.client.functions.invoke(
            'kyc_create_signed_url',
            body: {'bucket': bucket, 'object_path': normalized, 'expires_in': 60 * 15},
          );

          debugPrint(
            'AdminMerchantReview: signed-url fallback response status=${res.status} data=${res.data}',
          );

          final data = res.data;
          final url = (data is Map) ? (data['url']?.toString()) : null;
          if (url != null && url.trim().isNotEmpty) {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
              debugPrint('AdminMerchantReview: signed-url fallback launchUrl ok=$ok uri=$uri');
              if (ok) return;
              throw 'Could not open the signed document URL.';
            }
            throw 'Signed URL was invalid.';
          }
          throw 'Signed URL was missing from the Edge Function response.';
        } catch (fallbackError, st) {
          debugPrint('AdminMerchantReview: signed-url fallback failed: $fallbackError\n$st');
        }
      }

      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      final msg = attemptedFallback
          ? 'Could not open the document link. The file may exist, but access is restricted or the browser blocked the link.'
          : (isNotFound
              ? 'Document not found in storage (404). It may have been deleted, or the bucket/path is incorrect.'
              : 'Failed to open document: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, style: TextStyle(color: scheme.onErrorContainer)),
          backgroundColor: scheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      final bucket = AppConstants.kycStorageBucket;
      final normalized = _normalizeObjectPath(bucket: bucket, raw: objectPath);
      debugPrint('AdminMerchantReview: open document failed. bucket=$bucket object=$normalized error=$e');
      if (!mounted) return;
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open document: $e', style: TextStyle(color: scheme.onErrorContainer)),
          backgroundColor: scheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }
}

class _LogoPreviewRow extends StatefulWidget {
  final String label;
  final String? objectPath;
  const _LogoPreviewRow({required this.label, required this.objectPath});

  @override
  State<_LogoPreviewRow> createState() => _LogoPreviewRowState();
}

class _LogoPreviewRowState extends State<_LogoPreviewRow> {
  bool _loading = false;
  String? _url;

  String? _normalizeObjectPath({required String bucket, required String raw}) {
    final s = raw.trim();
    if (s.isEmpty) return null;

    final uri = Uri.tryParse(s);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) return s;

    var path = s;
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('$bucket/')) path = path.substring(bucket.length + 1);

    if (path.contains('storage/v1/object/')) {
      final parsed = Uri.tryParse('https://dummy/$path');
      final segments = parsed?.pathSegments ?? const <String>[];
      final i = segments.indexWhere((e) => e == 'public' || e == 'sign');
      if (i != -1 && segments.length >= i + 2) {
        final bucketSeg = segments[i + 1];
        if (bucketSeg == bucket && segments.length > i + 2) {
          path = segments.sublist(i + 2).join('/');
        }
      }
    }

    return path.trim().isEmpty ? null : path;
  }

  Future<void> _ensureUrl() async {
    if (_loading) return;
    final raw = widget.objectPath;
    if (raw == null || raw.trim().isEmpty) return;

    setState(() => _loading = true);
    try {
      final bucket = AppConstants.kycStorageBucket;
      final normalized = _normalizeObjectPath(bucket: bucket, raw: raw);
      if (normalized == null) throw 'Missing logo path.';

      final direct = Uri.tryParse(normalized);
      final isDirectUrl = direct != null && (direct.scheme == 'http' || direct.scheme == 'https');
      if (isDirectUrl) {
        if (mounted) setState(() => _url = normalized);
        return;
      }

      try {
        final url = await SupabaseConfig.client.storage.from(bucket).createSignedUrl(normalized, 60 * 15);
        if (mounted) setState(() => _url = url);
        return;
      } on StorageException catch (e) {
        final status = e.statusCode?.toString();
        final isNotFound = status == '404' || e.message.toLowerCase().contains('not found');
        debugPrint('AdminMerchantReview: logo signed-url failed (storage). bucket=$bucket object=$normalized error=$e');
        if (isNotFound) {
          debugPrint('AdminMerchantReview: attempting Edge Function signed-url fallback for logo...');
          final res = await SupabaseConfig.client.functions.invoke(
            'kyc_create_signed_url',
            body: {'bucket': bucket, 'object_path': normalized, 'expires_in': 60 * 15},
          );
          debugPrint('AdminMerchantReview: logo signed-url fallback response status=${res.status} data=${res.data}');
          final data = res.data;
          final url = (data is Map) ? (data['url']?.toString()) : null;
          if (url != null && url.trim().isNotEmpty) {
            if (mounted) setState(() => _url = url);
            return;
          }
        }
        rethrow;
      }
    } catch (e) {
      debugPrint('AdminMerchantReview: failed to build logo URL: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    await _ensureUrl();
    final url = _url;
    if (url == null || url.trim().isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    debugPrint('AdminMerchantReview: open logo launchUrl ok=$ok uri=$uri');
    if (!ok && mounted) {
      final scheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open logo link.', style: TextStyle(color: scheme.onErrorContainer)),
          backgroundColor: scheme.errorContainer,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final raw = widget.objectPath;
    final hasLogo = (raw ?? '').trim().isNotEmpty;

    // Lazily fetch the logo URL when this row first builds.
    if (hasLogo && _url == null && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureUrl());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 6,
            child: hasLogo
                ? Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: scheme.surfaceContainerHighest,
                          border: Border.all(color: scheme.outline),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _loading
                            ? Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                                ),
                              )
                            : (_url == null
                                ? Icon(Icons.image_outlined, color: scheme.onSurfaceVariant)
                                : Image.network(
                                    _url!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('AdminMerchantReview: logo preview load failed: $error');
                                      return Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant);
                                    },
                                  )),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: _loading ? null : _open,
                        icon: Icon(Icons.open_in_new_rounded, size: 18, color: scheme.primary),
                        label: Text('Open', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary)),
                      ),
                    ],
                  )
                : Text('—', style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _BottomDecisionBar extends StatelessWidget {
  final bool isBusy;
  final VoidCallback? onReject;
  final VoidCallback? onApprove;

  const _BottomDecisionBar({required this.isBusy, required this.onReject, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
              child: isBusy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Reject'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ElevatedButton(
              onPressed: onApprove,
              child: isBusy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Approve'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectMerchantReasonSheet extends StatefulWidget {
  final String businessName;
  const _RejectMerchantReasonSheet({required this.businessName});

  @override
  State<_RejectMerchantReasonSheet> createState() => _RejectMerchantReasonSheetState();
}

class _RejectMerchantReasonSheetState extends State<_RejectMerchantReasonSheet> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, bottomInset + AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reject ${widget.businessName}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide a short reason. This will be emailed to the merchant.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Rejection reason',
              errorText: _error,
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => context.pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _error = 'Reason is required.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    // Close immediately with the reason; the caller performs the reject API call.
    context.pop(trimmed);
  }
}

class _ConfirmRejectSheet extends StatelessWidget {
  final String businessName;
  const _ConfirmRejectSheet({required this.businessName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reject $businessName?', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'You’re about to reject this merchant’s request. You can still review their information before confirming.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(false),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: scheme.errorContainer, foregroundColor: scheme.onErrorContainer),
                  child: const Text('Yes, reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
