import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:caddymoney/models/user_model.dart';
import 'package:caddymoney/services/auth_service.dart';
import 'package:caddymoney/core/enums/app_role.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  AppRole? get userRole => _currentUser?.role;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authService.authStateChanges.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _loadCurrentUser();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });

    await _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    _isLoading = false;
    
    if (result['success'] == true) {
      _currentUser = result['profile'];
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpUser({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signUpUser(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );

    _isLoading = false;

    if (result['success'] == true) {
      await _loadCurrentUser();
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpMerchant({
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
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.signUpMerchant(
      email: email,
      password: password,
      businessName: businessName,
      ownerName: ownerName,
      phone: phone,
      businessCategory: businessCategory,
      address: address,
      city: city,
      country: country,
    );

    _isLoading = false;

    if (result['success'] == true) {
      await _loadCurrentUser();
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
