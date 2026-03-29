import 'package:flutter/foundation.dart';
import 'package:caddymoney/models/transaction_model.dart';
import 'package:caddymoney/core/config/supabase_config.dart';

class TransferResult {
  final bool success;
  final String? error;
  final String? transactionId;
  final String? transactionReference;

  const TransferResult({required this.success, this.error, this.transactionId, this.transactionReference});

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    return TransferResult(
      success: json['success'] == true,
      error: json['error'] as String?,
      transactionId: json['transaction_id']?.toString(),
      transactionReference: json['transaction_reference']?.toString(),
    );
  }
}

class TransactionService {
  Future<String?> findActiveUserIdByEmail(String email) async {
    try {
      final cleaned = email.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (cleaned.isEmpty) return null;

      final matches = await SupabaseConfig.client.rpc(
        'find_active_profiles',
        params: {'p_identifier': cleaned, 'p_limit': 10},
      );
      final list = (matches as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (list.isEmpty) return null;

      final chosen = list.firstWhere(
        (m) => (m['email']?.toString().toLowerCase() ?? '') == cleaned,
        orElse: () => <String, dynamic>{},
      );
      final id = chosen['id']?.toString();
      return (id == null || id.isEmpty) ? null : id;
    } catch (e) {
      debugPrint('TransactionService.findActiveUserIdByEmail failed: $e');
      return null;
    }
  }

  Future<List<TransactionModel>> listMyTransactions({int limit = 50}) async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return [];

      // Covers: sent user->user, received user->user, sent user->merchant.
      dynamic query = SupabaseService.from('transactions')
          .select('*')
          .or('sender_profile_id.eq.$uid,receiver_profile_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(limit);

      final rows = await query as List;
      return rows
          .whereType<Map>()
          .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('TransactionService.listMyTransactions failed: $e');
      return [];
    }
  }

  Future<TransferResult> transferUserToUser({
    required String receiverUserId,
    required double amount,
    String? note,
    String? paymentMethodId,
  }) async {
    try {
      final res = await SupabaseService.rpc(
        'transfer_user_to_user',
        params: {
          'receiver_user_id': receiverUserId,
          'transfer_amount': amount,
          'transfer_note': note,
          'payment_method_id': paymentMethodId,
        },
      );

      if (res is Map) return TransferResult.fromJson(Map<String, dynamic>.from(res));
      return const TransferResult(success: false, error: 'Unexpected RPC response');
    } catch (e) {
      debugPrint('TransactionService.transferUserToUser failed: $e');
      return TransferResult(success: false, error: e.toString());
    }
  }

  Future<TransferResult> transferUserToMerchant({
    required String merchantUniqueId,
    required double amount,
    String? note,
    String? paymentMethodId,
  }) async {
    try {
      final res = await SupabaseService.rpc(
        'transfer_user_to_merchant',
        params: {
          'merchant_unique_id': merchantUniqueId,
          'transfer_amount': amount,
          'transfer_note': note,
          'payment_method_id': paymentMethodId,
        },
      );

      if (res is Map) return TransferResult.fromJson(Map<String, dynamic>.from(res));
      return const TransferResult(success: false, error: 'Unexpected RPC response');
    } catch (e) {
      debugPrint('TransactionService.transferUserToMerchant failed: $e');
      return TransferResult(success: false, error: e.toString());
    }
  }
}
