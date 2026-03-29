import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:caddymoney/screens/splash_screen.dart';
import 'package:caddymoney/screens/role_selection_screen.dart';
import 'package:caddymoney/screens/auth/user_auth_screen.dart';
import 'package:caddymoney/screens/auth/merchant_auth_screen.dart';
import 'package:caddymoney/screens/auth/admin_login_screen.dart';
import 'package:caddymoney/screens/user/user_home_screen.dart';
import 'package:caddymoney/screens/merchant/merchant_dashboard_screen.dart';
import 'package:caddymoney/screens/admin/admin_dashboard_screen.dart';
import 'package:caddymoney/screens/settings_screen.dart';
import 'package:caddymoney/screens/settings/payment_methods_screen.dart';
import 'package:caddymoney/screens/user/profile_screen.dart';
import 'package:caddymoney/screens/user/receive_money_screen.dart';
import 'package:caddymoney/screens/user/send_money_screen.dart';
import 'package:caddymoney/screens/user/transactions_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
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
  static const String adminDashboard = '/admin-dashboard';
  static const String settings = '/settings';
  static const String paymentMethods = '/payment-methods';
  static const String sendMoney = '/send-money';
  static const String receiveMoney = '/receive-money';
  static const String transactions = '/transactions';
  static const String profile = '/profile';
}
