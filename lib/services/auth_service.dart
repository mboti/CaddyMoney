import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:caddymoney/models/user_model.dart';
import 'package:caddymoney/core/enums/app_role.dart';
import 'package:caddymoney/core/config/supabase_config.dart';

class AuthService {
  SupabaseClient get _supabase => SupabaseConfig.client;

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await SupabaseService.selectSingle(
        'profiles',
        filters: {'id': user.id},
      );
      if (response == null) return null;
      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cleanedEmail = _cleanEmail(email);
      final cleanedPassword = _cleanPassword(password);
      final response = await _supabase.auth.signInWithPassword(
        email: cleanedEmail,
        password: cleanedPassword,
      );

      if (response.user == null) {
        return {'success': false, 'error': 'Sign in failed'};
      }

      final profile = await getCurrentUserProfile();
      if (profile == null) {
        // This usually means the profile trigger failed or RLS prevents reads.
        // Treat it as a failure because the app relies on profile + role.
        return {
          'success': false,
          'error': 'Profile not found. Please contact support or try again.',
        };
      }

      // If the user is a merchant and email confirmations are enabled, the merchant
      // row may not have been created at signup time (because there was no session).
      // Repair it on first successful sign-in.
      if (profile.role == AppRole.merchant) {
        await _ensureMerchantRowExistsFromAuthMetadata();
      }
      return {'success': true, 'profile': profile};
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return {
        'success': false,
        'error': e.message,
        'code': e.statusCode,
        'isEmailNotConfirmed': _looksLikeEmailNotConfirmed(e.message),
      };
    } catch (e) {
      debugPrint('Sign in error: $e');
      return {'success': false, 'error': 'An error occurred during sign in'};
    }
  }

  Future<Map<String, dynamic>> signUpUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final cleanedEmail = _cleanEmail(email);
      final cleanedPassword = _cleanPassword(password);
      final response = await _supabase.auth.signUp(
        email: cleanedEmail,
        password: cleanedPassword,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': AppRole.standardUser.toJson(),
        },
      );

      if (response.user == null) {
        return {'success': false, 'error': 'Sign up failed'};
      }

      // If email confirmations are enabled in Supabase Auth,
      // signUp returns a user but no active session until the user confirms.
      final needsEmailConfirmation = response.session == null;
      return {
        'success': true,
        'user': response.user,
        'needsEmailConfirmation': needsEmailConfirmation,
        'email': cleanedEmail,
      };
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return {'success': false, 'error': e.message};
    } catch (e) {
      debugPrint('Sign up error: $e');
      return {'success': false, 'error': 'An error occurred during sign up'};
    }
  }

  Future<Map<String, dynamic>> signUpMerchant({
    required String email,
    required String password,
    required String businessName,
    required String ownerName,
    String? phone,
    String? businessCategory,
    String? address,
    String? city,
    String? country,
  }) async {
    try {
      final cleanedEmail = _cleanEmail(email);
      final cleanedPassword = _cleanPassword(password);
      final authResponse = await _supabase.auth.signUp(
        email: cleanedEmail,
        password: cleanedPassword,
        data: {
          'full_name': ownerName,
          'phone': phone,
          'role': AppRole.merchant.toJson(),
          // Store merchant application fields in auth metadata so we can create the
          // merchants row after email confirmation (when a session exists).
          'merchant_business_name': businessName,
          'merchant_owner_name': ownerName,
          'merchant_business_email': cleanedEmail,
          'merchant_business_phone': phone,
          'merchant_business_category': businessCategory,
          'merchant_address_line1': address,
          'merchant_city': city,
          'merchant_country_code': country,
        },
      );

      if (authResponse.user == null) {
        return {'success': false, 'error': 'Merchant registration failed'};
      }

      // If email confirmations are enabled, signUp returns no session until the user
      // confirms their email. Without a session, the client is effectively anon and
      // cannot insert into protected tables (permission denied).
      //
      // In that case, we defer creating the merchants row until the first sign-in
      // after confirmation (see _ensureMerchantRowExistsFromAuthMetadata()).
      if (authResponse.session != null) {
        final merchantData = {
          'profile_id': authResponse.user!.id,
          'business_name': businessName,
          'owner_name': ownerName,
          'business_email': cleanedEmail,
          'business_phone': phone,
          'business_category': businessCategory,
          'address_line1': address,
          'city': city,
          'country_code': country,
          'status': 'pending',
        };
        await _supabase.from('merchants').insert(merchantData);
      }

      final needsEmailConfirmation = authResponse.session == null;
      return {
        'success': true,
        'user': authResponse.user,
        'needsEmailConfirmation': needsEmailConfirmation,
        'email': cleanedEmail,
      };
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return {'success': false, 'error': e.message};
    } catch (e) {
      debugPrint('Merchant registration error: $e');
      return {'success': false, 'error': 'An error occurred during registration'};
    }
  }

  Future<void> _ensureMerchantRowExistsFromAuthMetadata() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final existing = await SupabaseService.selectSingle('merchants', filters: {'profile_id': user.id});
      if (existing != null) return;

      final md = user.userMetadata ?? const <String, dynamic>{};
      final merchantData = {
        'profile_id': user.id,
        'business_name': (md['merchant_business_name'] ?? '').toString().trim(),
        'owner_name': (md['merchant_owner_name'] ?? md['full_name'] ?? '').toString().trim(),
        'business_email': (md['merchant_business_email'] ?? user.email ?? '').toString().trim().toLowerCase(),
        'business_phone': md['merchant_business_phone'],
        'business_category': md['merchant_business_category'],
        'address_line1': md['merchant_address_line1'],
        'city': md['merchant_city'],
        'country_code': md['merchant_country_code'],
        'status': 'pending',
      };

      // Don't attempt an insert if we have no meaningful merchant name; this keeps
      // the table clean in case metadata is missing.
      if ((merchantData['business_name'] as String).isEmpty) {
        debugPrint('Merchant metadata missing business_name; skipping merchants row creation.');
        return;
      }

      await SupabaseService.insert('merchants', merchantData);
    } catch (e) {
      // Sign-in should still succeed even if this repair fails.
      debugPrint('Failed to ensure merchant row exists: $e');
    }
  }

  Future<bool> resendSignupConfirmationEmail(String email) async {
    try {
      final cleanedEmail = _cleanEmail(email);
      await _supabase.auth.resend(type: OtpType.signup, email: cleanedEmail);
      return true;
    } on AuthException catch (e) {
      debugPrint('Resend confirmation auth error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Resend confirmation error: $e');
      return false;
    }
  }

  String _cleanEmail(String input) => input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  String _cleanPassword(String input) => input.trim();

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } catch (e) {
      debugPrint('Password reset error: $e');
      return false;
    }
  }

  bool _looksLikeEmailNotConfirmed(String message) {
    final m = message.toLowerCase();
    return m.contains('email not confirmed') ||
        m.contains('email address not confirmed') ||
        m.contains('not confirmed');
  }

  Future<Map<String, dynamic>> createAdminFromBootstrap({
    required String email,
    required String password,
    required String fullName,
    required String bootstrapToken,
  }) async {
    try {
      final cleanedEmail = _cleanEmail(email);
      final cleanedPassword = _cleanPassword(password);
      final cleanedName = fullName.trim();

      final res = await _supabase.functions.invoke(
        'admin_create_admin',
        body: {
          'email': cleanedEmail,
          'password': cleanedPassword,
          'full_name': cleanedName,
          'bootstrap_token': bootstrapToken.trim(),
        },
      );

      final data = res.data;
      if (data is Map) {
        final success = data['success'] == true;
        if (success) return {'success': true, 'userId': data['user_id']};
        return {
          'success': false,
          'error': (data['error'] ?? 'Failed to create admin').toString(),
        };
      }

      // Some errors can surface as non-map payloads.
      return {'success': false, 'error': 'Failed to create admin'};
    } on FunctionException catch (e) {
      debugPrint('Create admin function error: ${e.toString()}');
      return {'success': false, 'error': e.toString()};
    } catch (e) {
      debugPrint('Create admin error: $e');
      return {'success': false, 'error': 'An error occurred while creating the admin'};
    }
  }
}
