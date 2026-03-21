import 'package:flutter/foundation.dart';
import 'package:caddymoney/models/wallet_model.dart';
import 'package:caddymoney/supabase/supabase_config.dart';

class WalletService {
  Future<WalletModel?> getMyUserWallet() async {
    try {
      final uid = SupabaseConfig.auth.currentUser?.id;
      if (uid == null) return null;

      final row = await SupabaseService.selectSingle(
        'wallets',
        filters: {'owner_type': 'user', 'profile_id': uid, 'is_active': true},
      );
      if (row == null) return null;
      return WalletModel.fromJson(row);
    } catch (e) {
      debugPrint('WalletService.getMyUserWallet failed: $e');
      return null;
    }
  }

  Future<WalletModel?> getMerchantWallet({required String merchantId}) async {
    try {
      final row = await SupabaseService.selectSingle(
        'wallets',
        filters: {'owner_type': 'merchant', 'merchant_id': merchantId, 'is_active': true},
      );
      if (row == null) return null;
      return WalletModel.fromJson(row);
    } catch (e) {
      debugPrint('WalletService.getMerchantWallet failed: $e');
      return null;
    }
  }
}
