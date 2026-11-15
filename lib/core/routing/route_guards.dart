import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';
import '../constants/app_constants.dart';
import '../../shared/models/auth_state.dart';
import '../../shared/models/user_model.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Listenable bridge to trigger GoRouter recalculation when AuthState changes
class AuthRouterListenable extends ChangeNotifier {
  final Ref _ref;

  AuthRouterListenable(this._ref) {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        if (previous?.status != next.status ||
            previous?.user?.mustChangePassword != next.user?.mustChangePassword ||
            previous?.user?.termsAccepted != next.user?.termsAccepted ||
            previous?.user?.acceptedTermsVersion != next.user?.acceptedTermsVersion ||
            previous?.user?.role != next.user?.role ||
            previous?.user?.status != next.user?.status) {
          notifyListeners();
        }
      },
    );
  }
}

/// Helper to determine role-based home destination
String getRoleHomeRoute(UserModel? user) {
  if (user == null || user.isGuest) return AppRoutes.home;
  if (user.isAdmin) return AppRoutes.adminDashboard;
  if (user.isEmployee || user.isBarista) return AppRoutes.staffOrders;
  return AppRoutes.home;
}

/// Global Route Guard & Role-Based Redirection Logic
String? appRouteGuard(BuildContext context, GoRouterState state, dynamic ref) {
  final AuthState authState = (ref as dynamic).read(authNotifierProvider) as AuthState;
  final matchedLocation = state.matchedLocation;

  // If auth is still initial bootstrapping, allow splash to proceed
  if (authState.isInitial && matchedLocation == AppRoutes.splash) {
    return null;
  }

  final isAuthenticated = authState.isAuthenticated;
  final user = authState.user;
  final isUnauthOnlyRoute = AppRoutes.unauthOnlyRoutes.contains(matchedLocation);

  // 1. MANDATORY FIRST-LOGIN PASSWORD SETUP INTERCEPTION
  if (isAuthenticated && user != null && !user.isGuest) {
    if (user.mustChangePassword) {
      if (matchedLocation != AppRoutes.firstLoginSetup) {
        return AppRoutes.firstLoginSetup;
      }
      return null;
    } else if (matchedLocation == AppRoutes.firstLoginSetup) {
      // User has already completed password setup; redirect to role-specific home
      return getRoleHomeRoute(user);
    }

    // 2. MANDATORY TERMS & CONDITIONS ACCEPTANCE INTERCEPTION
    final isReviewMode = state.uri.queryParameters['mode'] == 'review';
    final hasAcceptedCurrentTerms = user.hasAcceptedTerms(AppConstants.currentTermsVersion);

    if (!hasAcceptedCurrentTerms) {
      if (matchedLocation != AppRoutes.termsAndConditions) {
        return AppRoutes.termsAndConditions;
      }
      return null; // Remain on terms screen until accepted
    } else if (matchedLocation == AppRoutes.termsAndConditions && !isReviewMode) {
      // User has already accepted current terms; redirect to role-specific home
      return getRoleHomeRoute(user);
    }
  }

  // 3. UNAUTH-ONLY ROUTES (Redirect already logged-in users away from login/register to role home)
  if (isAuthenticated && isUnauthOnlyRoute && user != null && !user.isGuest) {
    return getRoleHomeRoute(user);
  }

  // 3. STRICT CUSTOMER-ONLY ROUTES PROTECTION
  // Authenticated Admin and Staff must NEVER be routed into or presented with Customer Shopping UI
  final isCustomerOnlyRoute = AppRoutes.customerOnlyRoutes.any(
    (route) => matchedLocation == route || matchedLocation.startsWith('$route/'),
  );

  if (isCustomerOnlyRoute) {
    if (isAuthenticated && user != null && !user.isGuest) {
      if (user.isAdmin) {
        // Admin forbidden from customer shopping/cart/orders UI
        return AppRoutes.adminDashboard;
      }
      if (user.isEmployee || user.isBarista) {
        // Staff/Barista forbidden from customer shopping UI
        return AppRoutes.staffOrders;
      }
    }

    // Check if customer route requires authentication (Cart, Checkout, Customer Orders, Profile)
    final isProtectedCustomer = AppRoutes.protectedCustomerRoutes.any(
      (route) => matchedLocation == route || matchedLocation.startsWith('$route/'),
    );

    if (!isAuthenticated && isProtectedCustomer) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(matchedLocation)}';
    }

    if (user != null && user.isGuest && (matchedLocation == AppRoutes.checkout || matchedLocation.startsWith('${AppRoutes.checkout}/'))) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(matchedLocation)}';
    }

    return null;
  }

  // 4. CHECK PRIVILEGED ADMIN-ONLY ROUTES (Employees & Customers forbidden)
  final isAdminOnlyRoute = AppRoutes.adminOnlyRoutes.any(
    (route) => matchedLocation == route || matchedLocation.startsWith('$route/'),
  );

  if (isAdminOnlyRoute) {
    if (!isAuthenticated || user == null) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(matchedLocation)}';
    }
    if (!user.isAdmin) {
      // Employee/Barista attempting to access Admin Accounts or BI is sent to Staff Orders
      return (user.isEmployee || user.isBarista) ? AppRoutes.staffOrders : AppRoutes.home;
    }
    return null;
  }

  // 5. CHECK STAFF OPERATIONS ROUTES (Customers forbidden)
  final isStaffRoute = AppRoutes.staffRoutes.any(
    (route) => matchedLocation == route || matchedLocation.startsWith('$route/'),
  );

  if (isStaffRoute) {
    if (!isAuthenticated || user == null) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(matchedLocation)}';
    }
    if (user.isCustomer) {
      // Customers cannot access staff operations
      return AppRoutes.home;
    }
    if (matchedLocation == AppRoutes.staffDashboard) {
      return user.isAdmin ? AppRoutes.adminDashboard : AppRoutes.staffOrders;
    }
    return null;
  }

  // 6. CHECK OPERATIONAL BUSINESS ROUTES (Admin and Staff allowed; Customers forbidden)
  final isOperationalRoute = AppRoutes.operationalRoutes.any(
    (route) => matchedLocation == route || matchedLocation.startsWith('$route/'),
  );

  if (isOperationalRoute) {
    if (!isAuthenticated || user == null) {
      return '${AppRoutes.login}?redirect=${Uri.encodeComponent(matchedLocation)}';
    }
    if (!user.isBusinessUser) {
      return AppRoutes.home;
    }
    return null;
  }

  // 7. GENERIC FALLBACK FOR PROTECTED ROUTES (Unauthenticated & Guests must sign in)
  final isProtected = AppRoutes.protectedRoutes.any(
    (route) => matchedLocation == route || matchedLocation.startsWith('$route/'),
  );

  if ((!isAuthenticated || (user != null && user.isGuest)) && isProtected) {
    return '${AppRoutes.login}?redirect=${Uri.encodeComponent(matchedLocation)}';
  }

  return null;
}
