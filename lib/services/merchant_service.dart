import 'package:flutter/foundation.dart';
import 'package:caddymoney/core/constants/app_constants.dart';
import 'package:caddymoney/models/merchant_model.dart';
import 'package:caddymoney/core/config/supabase_config.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantService {
  Future<({bool ok, String? error})> updateMyMerchantKycResult({
    required String businessType,
    String? registrationNumber,
    String? vatNumber,
    required DateTime dateOfBirth,
    required String nationality,
    required String iban,
    required String accountHolderName,
    required List<String> categories,
    String? idDocumentPath,
    String? businessRegistrationDocPath,
    String? logoPath,
    bool submitForReview = true,
    // Used only as a fallback when the merchants row doesn't exist yet.
    String? businessName,
    String? ownerFirstName,
    String? ownerLastName,
    String? businessEmail,
    String? businessPhone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? countryName,
  }) async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return (ok: false, error: 'Not signed in.');

      String? currentStatus;
      if (submitForReview) {
        try {
          final existing = await SupabaseService.selectSingle('merchants', filters: {'profile_id': uid});
          currentStatus = existing?['status']?.toString();
        } catch (e) {
          debugPrint('MerchantService.updateMyMerchantKyc failed to read current status: $e');
        }
      }

      Future<List<dynamic>> doUpdate({required bool includeLogo}) async {
        final dobString = '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}';
        final payload = <String, dynamic>{
          'business_type': businessType,
          'registration_number': registrationNumber,
          'vat_number': vatNumber,
          // Postgres column type is DATE (not timestamptz). Send YYYY-MM-DD.
          'date_of_birth': dobString,
          'nationality': nationality,
          'iban': iban,
          'account_holder_name': accountHolderName,
          'categories': categories,
          'id_document_path': idDocumentPath,
          'business_registration_doc_path': businessRegistrationDocPath,
          'profile_completed': true,
          'profile_completed_at': DateTime.now().toIso8601String(),
        };

        // Mark as pending when a merchant submits KYC, but don't downgrade approved merchants.
        if (submitForReview && (currentStatus == null || currentStatus.toLowerCase() != 'approved')) {
          payload['status'] = 'pending';
        }
        if (includeLogo && logoPath != null) payload['logo_path'] = logoPath;
        return await SupabaseService.update('merchants', payload, filters: {'profile_id': uid});
      }

      List<dynamic> updated;
      try {
        updated = await doUpdate(includeLogo: true);
      } catch (e) {
        // Backward-compatible: if the DB schema doesn't include `logo_path` yet,
        // retry without it so merchants can still submit KYC.
        if (logoPath != null) {
          debugPrint('Update with logo_path failed; retrying without logo_path. Error: $e');
          updated = await doUpdate(includeLogo: false);
        } else {
          rethrow;
        }
      }

      if (updated.isNotEmpty) return (ok: true, error: null);

      debugPrint('MerchantService.updateMyMerchantKyc: update returned 0 rows for profile_id=$uid');
      // Fallback: ensure the merchant row exists (edge function uses service role).
      final bootstrapError = await _ensurePendingMerchantRow(
        profileId: uid,
        businessName: businessName,
        ownerFirstName: ownerFirstName,
        ownerLastName: ownerLastName,
        businessEmail: businessEmail,
        businessPhone: businessPhone,
        categories: categories,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        postalCode: postalCode,
        countryName: countryName,
      );

      if (bootstrapError != null) {
        return (ok: false, error: bootstrapError);
      }

      // Retry update now that the row should exist.
      updated = await doUpdate(includeLogo: logoPath != null);
      if (updated.isNotEmpty) return (ok: true, error: null);
      return (
        ok: false,
        error: 'Merchant record could not be updated. This is usually caused by Supabase RLS policies. Please contact support.',
      );
    } catch (e) {
      debugPrint('MerchantService.updateMyMerchantKycResult failed: $e');
      return (ok: false, error: e.toString());
    }
  }

  Future<String?> _ensurePendingMerchantRow({
    required String profileId,
    required List<String> categories,
    String? businessName,
    String? ownerFirstName,
    String? ownerLastName,
    String? businessEmail,
    String? businessPhone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? countryName,
  }) async {
    try {
      // If we can already read the row, don't do anything.
      try {
        final existing = await SupabaseService.selectSingle('merchants', filters: {'profile_id': profileId});
        if (existing != null) return null;
      } catch (_) {
        // Ignore; we might not have read permissions.
      }

      final bn = (businessName ?? '').trim();
      final fn = (ownerFirstName ?? '').trim();
      final ln = (ownerLastName ?? '').trim();
      final em = (businessEmail ?? '').trim().toLowerCase();
      if (bn.isEmpty || fn.isEmpty || ln.isEmpty || em.isEmpty) {
        return 'We could not create your merchant record because some basic business details are missing. Please go back to Step 1 and ensure Business name, First name, Last name and Email are filled.';
      }

      final payload = {
        'profile_id': profileId,
        'business_name': bn,
        'owner_first_name': fn,
        'owner_last_name': ln,
        'business_email': em,
        'business_phone': (businessPhone ?? '').trim(),
        'categories': categories,
        'address_line1': (addressLine1 ?? '').trim(),
        'address_line2': (addressLine2 ?? '').trim().isEmpty ? null : (addressLine2 ?? '').trim(),
        'city': (city ?? '').trim(),
        'postal_code': (postalCode ?? '').trim(),
        'country_name': (countryName ?? '').trim(),
        'status': 'pending',
        'profile_completed': false,
      };

      final res = await SupabaseConfig.client.functions.invoke('merchant_create_pending', body: payload);
      final data = res.data;
      if (data is Map && data['success'] == true) return null;
      final err = (data is Map ? data['error'] : null)?.toString();
      debugPrint('merchant_create_pending fallback returned: $data');
      return err == null || err.isEmpty ? 'Failed to create merchant record. Please try again.' : err;
    } on FunctionException catch (e) {
      debugPrint('merchant_create_pending fallback function error: $e');
      // Edge functions often return a JSON body in `details`.
      final details = e.details;
      if (details is Map && details['error'] != null) {
        final msg = details['error'].toString().trim();
        if (msg.isNotEmpty) return msg;
      }
      return 'Failed to create merchant record (${e.status}). Please try again.';
    } catch (e) {
      debugPrint('MerchantService._ensurePendingMerchantRow failed: $e');
      return e.toString();
    }
  }
  Future<MerchantModel?> getMyMerchant() async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return null;

      final row = await SupabaseService.selectSingle(
        'merchants',
        filters: {'profile_id': uid},
      );
      if (row == null) return null;
      return MerchantModel.fromJson(row);
    } catch (e) {
      debugPrint('MerchantService.getMyMerchant failed: $e');
      return null;
    }
  }

  Future<List<MerchantModel>> listMerchants({String? status, List<String>? statuses, bool? profileCompleted, int limit = 100}) async {
    try {
      return await _listMerchantsRaw(status: status, statuses: statuses, profileCompleted: profileCompleted, limit: limit);
    } catch (e) {
      debugPrint('MerchantService.listMerchants failed: $e');
      return [];
    }
  }

  Future<List<MerchantModel>> _listMerchantsRaw({String? status, List<String>? statuses, bool? profileCompleted, int limit = 100}) async {
    dynamic query = SupabaseService.from('merchants').select('*');
    if (statuses != null && statuses.isNotEmpty) {
      query = query.inFilter('status', statuses);
    } else if (status != null) {
      query = query.eq('status', status);
    }
    if (profileCompleted != null) {
      query = query.eq('profile_completed', profileCompleted);
    }
    query = query.order('created_at', ascending: false).limit(limit);
    final rows = await query as List;
    return rows
        .whereType<Map>()
        .map((e) => MerchantModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<({List<MerchantModel> merchants, String? error})> listMerchantsResult({String? status, List<String>? statuses, bool? profileCompleted, int limit = 100}) async {
    try {
      final items = await _listMerchantsRaw(status: status, statuses: statuses, profileCompleted: profileCompleted, limit: limit);
      return (merchants: items, error: null);
    } catch (e) {
      debugPrint('MerchantService.listMerchantsResult failed: $e');
      return (merchants: const <MerchantModel>[], error: e.toString());
    }
  }

  Future<bool> approveMerchant({required String merchantId, String? reason}) async {
    try {
      final adminId = SupabaseConfig.auth.currentUser?.id;
      if (adminId == null) return false;

      final existing = await SupabaseService.selectSingle(
        'merchants',
        filters: {'id': merchantId},
      );
      if (existing == null) return false;
      final oldStatus = existing['status'];

      await SupabaseService.update(
        'merchants',
        {
          'status': 'approved',
          'approved_by': adminId,
          'approved_at': DateTime.now().toIso8601String(),
          'rejected_reason': null,
          'suspended_reason': null,
        },
        filters: {'id': merchantId},
      );

      await SupabaseService.insert(
        'merchant_status_history',
        {
          'merchant_id': merchantId,
          'old_status': oldStatus,
          'new_status': 'approved',
          'changed_by': adminId,
          'reason': reason,
        },
      );

      return true;
    } catch (e) {
      debugPrint('MerchantService.approveMerchant failed: $e');
      return false;
    }
  }

  Future<bool> rejectMerchant({required String merchantId, required String reason}) async {
    try {
      final adminId = SupabaseConfig.auth.currentUser?.id;
      if (adminId == null) return false;

      final existing = await SupabaseService.selectSingle(
        'merchants',
        filters: {'id': merchantId},
      );
      if (existing == null) return false;
      final oldStatus = existing['status'];

      await SupabaseService.update(
        'merchants',
        {
          'status': 'rejected',
          'approved_by': null,
          'approved_at': null,
          'rejected_reason': reason,
        },
        filters: {'id': merchantId},
      );

      await SupabaseService.insert(
        'merchant_status_history',
        {
          'merchant_id': merchantId,
          'old_status': oldStatus,
          'new_status': 'rejected',
          'changed_by': adminId,
          'reason': reason,
        },
      );

      return true;
    } catch (e) {
      debugPrint('MerchantService.rejectMerchant failed: $e');
      return false;
    }
  }

  Future<bool> updateMyMerchantKyc({
    required String businessType,
    String? registrationNumber,
    String? vatNumber,
    required DateTime dateOfBirth,
    required String nationality,
    required String iban,
    required String accountHolderName,
    required List<String> categories,
    String? idDocumentPath,
    String? businessRegistrationDocPath,
    String? logoPath,
    bool submitForReview = true,
    String? businessName,
    String? ownerFirstName,
    String? ownerLastName,
    String? businessEmail,
    String? businessPhone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? postalCode,
    String? countryName,
  }) async {
    final res = await updateMyMerchantKycResult(
      businessType: businessType,
      registrationNumber: registrationNumber,
      vatNumber: vatNumber,
      dateOfBirth: dateOfBirth,
      nationality: nationality,
      iban: iban,
      accountHolderName: accountHolderName,
      categories: categories,
      idDocumentPath: idDocumentPath,
      businessRegistrationDocPath: businessRegistrationDocPath,
      logoPath: logoPath,
      submitForReview: submitForReview,
      businessName: businessName,
      ownerFirstName: ownerFirstName,
      ownerLastName: ownerLastName,
      businessEmail: businessEmail,
      businessPhone: businessPhone,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      postalCode: postalCode,
      countryName: countryName,
    );
    if (!res.ok) debugPrint('MerchantService.updateMyMerchantKyc returning false: ${res.error}');
    return res.ok;
  }

  Future<({String? path, String? error})> uploadMerchantDocument({
    required String docType,
    required XFile file,
  }) async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return (path: null, error: 'Not signed in.');

      final bytes = await file.readAsBytes();
      final name = file.name;
      final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'merchant/$uid/$docType/${DateTime.now().millisecondsSinceEpoch}_$safeName';

      try {
        await SupabaseConfig.client.storage.from(AppConstants.kycStorageBucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(upsert: true),
            );
      } on StorageException catch (e) {
        debugPrint('MerchantService.uploadMerchantDocument failed (storage): $e');
        final status = e.statusCode?.toString();
        if (status == '404' || e.message.toLowerCase().contains('bucket not found')) {
          return (
            path: null,
            error: 'Storage bucket not found: "${AppConstants.kycStorageBucket}". Create it in Supabase Storage or update the bucket name in AppConstants.kycStorageBucket.',
          );
        }
        if (status == '403' && e.message.toLowerCase().contains('row-level security')) {
          return (
            path: null,
            error:
                'Upload blocked by Supabase Storage RLS (403). You need an INSERT policy on storage.objects for bucket "${AppConstants.kycStorageBucket}" that allows this user to upload to: $path',
          );
        }
        return (path: null, error: e.message);
      }

      return (path: path, error: null);
    } catch (e) {
      debugPrint('MerchantService.uploadMerchantDocument failed: $e');
      return (path: null, error: e.toString());
    }
  }
}
