import 'package:flutter/foundation.dart';
import 'package:caddymoney/core/constants/app_constants.dart';
import 'package:caddymoney/models/merchant_model.dart';
import 'package:caddymoney/core/config/supabase_config.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantService {
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

  Future<List<MerchantModel>> listMerchants({String? status, List<String>? statuses, int limit = 100}) async {
    try {
      dynamic query = SupabaseService.from('merchants').select('*');
      if (statuses != null && statuses.isNotEmpty) {
        query = query.inFilter('status', statuses);
      } else if (status != null) {
        query = query.eq('status', status);
      }
      query = query.order('created_at', ascending: false).limit(limit);
      final rows = await query as List;
      return rows
          .whereType<Map>()
          .map((e) => MerchantModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('MerchantService.listMerchants failed: $e');
      return [];
    }
  }

  Future<({List<MerchantModel> merchants, String? error})> listMerchantsResult({String? status, List<String>? statuses, int limit = 100}) async {
    try {
      final items = await listMerchants(status: status, statuses: statuses, limit: limit);
      return (merchants: items, error: null);
    } catch (e) {
      // listMerchants already catches, but keep this method future-proof.
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
  }) async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return false;

      String? currentStatus;
      if (submitForReview) {
        try {
          final existing = await SupabaseService.selectSingle('merchants', filters: {'profile_id': uid});
          currentStatus = existing?['status']?.toString();
        } catch (e) {
          debugPrint('MerchantService.updateMyMerchantKyc failed to read current status: $e');
        }
      }

      Future<void> doUpdate({required bool includeLogo}) async {
        final payload = <String, dynamic>{
          'business_type': businessType,
          'registration_number': registrationNumber,
          'vat_number': vatNumber,
          'date_of_birth': dateOfBirth.toIso8601String(),
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
        await SupabaseService.update('merchants', payload, filters: {'profile_id': uid});
      }

      try {
        await doUpdate(includeLogo: true);
      } catch (e) {
        // Backward-compatible: if the DB schema doesn't include `logo_path` yet,
        // retry without it so merchants can still submit KYC.
        if (logoPath != null) debugPrint('Update with logo_path failed; retrying without logo_path. Error: $e');
        await doUpdate(includeLogo: false);
      }
      return true;
    } catch (e) {
      debugPrint('MerchantService.updateMyMerchantKyc failed: $e');
      return false;
    }
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
