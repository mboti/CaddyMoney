import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:caddymoney/screens/splash_screen.dart';
import 'package:caddymoney/screens/role_selection_screen.dart';
import 'package:caddymoney/screens/auth/user_auth_screen.dart';
import 'package:caddymoney/screens/auth/merchant_auth_screen.dart';
import 'package:caddymoney/screens/auth/admin_login_screen.dart';
import 'package:caddymoney/screens/user/user_home_screen.dart';
import 'package:caddymoney/screens/merchant/merchant_dashboard_screen.dart';
import 'package:caddymoney/screens/merchant/merchant_onboarding_kyc_screen.dart';
import 'package:caddymoney/screens/admin/admin_dashboard_screen.dart';
import 'package:caddymoney/screens/settings_screen.dart';
import 'package:caddymoney/screens/settings/payment_methods_screen.dart';
import 'package:caddymoney/screens/user/profile_screen.dart';
import 'package:caddymoney/screens/user/receive_money_screen.dart';
import 'package:caddymoney/screens/user/send_money_screen.dart';
import 'package:caddymoney/screens/user/transactions_screen.dart';
import 'package:caddymoney/providers/auth_provider.dart';
import 'package:caddymoney/core/enums/app_role.dart';
import 'package:caddymoney/core/config/supabase_config.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefreshListenable(),
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final location = state.matchedLocation;

      final isMerchant = auth.userRole == AppRole.merchant;
      final isAuthed = auth.isAuthenticated;

      final isPublicRoute = location == AppRoutes.splash ||
          location == AppRoutes.roleSelection ||
          location == AppRoutes.userAuth ||
          location == AppRoutes.merchantAuth ||
          location == AppRoutes.adminLogin;

      // Always allow public routes.
      if (isPublicRoute) return null;

      // Require login for protected areas.
      // (Note: don't use naive startsWith('/merchant') because it matches '/merchant-auth'.)
      final isMerchantProtected = location == AppRoutes.merchantDashboard || location == AppRoutes.merchantOnboarding;
      final isUserProtected = location == AppRoutes.userHome ||
          location == AppRoutes.sendMoney ||
          location == AppRoutes.receiveMoney ||
          location == AppRoutes.transactions ||
          location == AppRoutes.profile ||
          location == AppRoutes.paymentMethods ||
          location == AppRoutes.settings;
      final isAdminProtected = location == AppRoutes.adminDashboard;

      if (!isAuthed && (isMerchantProtected || isUserProtected || isAdminProtected)) {
        return AppRoutes.roleSelection;
      }

      // Merchant access restriction: until KYC is complete AND verified.
      if (isMerchant && isAuthed) {
        final isOnboarding = location == AppRoutes.merchantOnboarding;

        // Only gate *merchant protected routes*.
        if (isMerchantProtected) {
          if (!auth.merchantHasFullAccess) {
            if (!isOnboarding) return AppRoutes.merchantOnboarding;
          } else {
            if (isOnboarding) return AppRoutes.merchantDashboard;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        name: 'role-selection',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: RoleSelectionScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.userAuth,
        name: 'user-auth',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: UserAuthScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.merchantAuth,
        name: 'merchant-auth',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MerchantAuthScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        name: 'admin-login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.userHome,
        name: 'user-home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: UserHomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.merchantDashboard,
        name: 'merchant-dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MerchantDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.merchantOnboarding,
        name: 'merchant-onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: MerchantOnboardingKycScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.paymentMethods,
        name: 'payment-methods',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: PaymentMethodsScreen(),
        ),
      ),

      // User flows
      GoRoute(
        path: AppRoutes.sendMoney,
        name: 'send-money',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SendMoneyScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.receiveMoney,
        name: 'receive-money',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ReceiveMoneyScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: TransactionsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ProfileScreen(),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String splash = '/';
  static const String roleSelection = '/role-selection';
  static const String userAuth = '/user-auth';
  static const String merchantAuth = '/merchant-auth';
  static const String adminLogin = '/admin-login';
  static const String userHome = '/user-home';
  static const String merchantDashboard = '/merchant-dashboard';
  static const String merchantOnboarding = '/merchant-onboarding';
  static const String adminDashboard = '/admin-dashboard';
  static const String settings = '/settings';
  static const String paymentMethods = '/payment-methods';
  static const String sendMoney = '/send-money';
  static const String receiveMoney = '/receive-money';
  static const String transactions = '/transactions';
  static const String profile = '/profile';
}

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable() {
    _sub = SupabaseConfig.client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
