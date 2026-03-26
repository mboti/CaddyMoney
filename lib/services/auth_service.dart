import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:caddymoney/models/user_model.dart';
import 'package:caddymoney/core/enums/app_role.dart';
import 'package:caddymoney/supabase/supabase_config.dart';

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
        },
      );

      if (authResponse.user == null) {
        return {'success': false, 'error': 'Merchant registration failed'};
      }

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
}
