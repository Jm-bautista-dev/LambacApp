/// Centralized API Endpoints for Lambac Coffee Roastery
class ApiEndpoints {
  ApiEndpoints._();

  // Authentication & Profile
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String requestRegisterOtp = '/auth/register/request-otp';
  static const String verifyRegisterOtp = '/auth/register/verify-otp';
  static const String resendRegisterOtp = '/auth/register/resend-otp';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String firstLoginPassword = '/auth/first-login-password';
  static const String userProfile = '/users/profile';
  static const String updateProfile = '/users/profile';
  static const String changePassword = '/users/change-password';

  // Business User Management (RBAC Privileged)
  static const String adminUsers = '/admin/users';
  static const String adminAdmins = '/admin/admins';
  static const String adminEmployees = '/admin/employees';
  static String adminUserDetail(String id) => '/admin/users/$id';
  static String adminUpdateUser(String id) => '/admin/users/$id';
  static String adminDisableUser(String id) => '/admin/users/$id/disable';
  static String adminEnableUser(String id) => '/admin/users/$id/enable';
  static String adminResetPassword(String id) => '/admin/users/$id/reset-password';
  static const String adminAuditLogs = '/admin/audit-logs';

  // Products & Menu
  static const String products = '/products';
  static String productDetail(String id) => '/products/$id';
  static const String categories = '/products/categories';
  static const String featuredProducts = '/products/featured';
  static const String searchProducts = '/products/search';

  // Cart & Ordering
  static const String cart = '/cart';
  static const String cartItems = '/cart/items';
  static String cartItem(String id) => '/cart/items/$id';
  static const String checkout = '/orders/checkout';
  static const String createOrder = '/orders';
  static const String orders = '/orders';
  static String orderDetail(String id) => '/orders/$id';
  static String cancelOrder(String id) => '/orders/$id/cancel';
  static String trackOrder(String id) => '/orders/$id/track';

  // Chat & Communication
  static const String chatConversations = '/chat/conversations';
  static String chatMessages(String conversationId) => '/chat/conversations/$conversationId/messages';
  static String sendMessage(String conversationId) => '/chat/conversations/$conversationId/messages';

  // Business & Analytics
  static const String businessMetrics = '/admin/metrics';
  static const String analyticsOverview = '/analytics/overview';
  static const String salesForecast = '/analytics/forecast/sales';
  static const String productDemandForecast = '/analytics/forecast/demand';
}
