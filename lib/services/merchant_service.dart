import 'package:flutter/foundation.dart';
import 'package:caddymoney/models/merchant_model.dart';
import 'package:caddymoney/supabase/supabase_config.dart';

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

  Future<List<MerchantModel>> listMerchants({String? status, int limit = 100}) async {
    try {
      dynamic query = SupabaseService.from('merchants').select('*');
      if (status != null) query = query.eq('status', status);
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
}
