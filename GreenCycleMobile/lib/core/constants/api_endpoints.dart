class ApiEndpoints {
  static const String baseUrl      = 'https://10.33.61.84:7031/api';
  static const String hubBaseUrl   = 'https://10.33.61.84:7031'; // SignalR base

  // Auth
  static const String login        = '$baseUrl/auth/login';
  static const String register     = '$baseUrl/auth/register';
  static const String sendOtp      = '$baseUrl/auth/send-otp';
  static const String googleLogin  = '$baseUrl/auth/google-login';
  static const String logout       = '$baseUrl/auth/logout';

  // Wallet
  static const String walletBalance      = '$baseUrl/wallet/balance';
  static const String walletTransactions = '$baseUrl/wallet/transactions';
  static const String walletDeposit      = '$baseUrl/wallet/deposit';

  // Orders
  static const String wasteCategories  = '$baseUrl/orders/waste-categories';
  static const String createOrder      = '$baseUrl/orders/create';
  static const String orderHistory     = '$baseUrl/orders/history';
  static const String yardOrderHistory = '$baseUrl/orders/yard-history';
  static const String orderDetail      = '$baseUrl/orders';

  // Pick-up lifecycle (Collector)
  static const String pendingPickupOrders = '$baseUrl/orders/pickup/pending';
  /// Sử dụng: '$assignCollectorBase/{orderId}/assign-collector'
  static const String assignCollectorBase = '$baseUrl/orders';
  /// Sử dụng: '$pickupStatusBase/{orderId}/pickup-status'
  static const String pickupStatusBase = '$baseUrl/orders';

  // Transactions (Drop-off / Pick-up)
  static const String initiateTransaction       = '$baseUrl/transactions/initiate';
  static const String initiatePickupTransaction = '$baseUrl/transactions/pickup-initiate';
  static const String confirmTransaction        = '$baseUrl/transactions/confirm';

  // SignalR Hub
  static const String transactionHub = '$hubBaseUrl/hubs/transaction';

  // Scrap Yards
  static const String nearbyYards    = '$baseUrl/yards/nearby';
  static const String yardDetails    = '$baseUrl/yards';
  static const String yardStatus     = '$baseUrl/yards/status';
  static const String yardStats      = '$baseUrl/yards/stats';
  static const String yardStatsChart = '$baseUrl/yards/stats/chart';
  static const String yardActivities = '$baseUrl/yards/recent-activities';
  static const String yardProfile    = '$baseUrl/yards/profile';

  // Vouchers & Reward Store
  static const String vouchers      = '$baseUrl/vouchers';
  static const String redeemVoucher = '$baseUrl/vouchers/redeem';
  static const String myVouchers    = '$baseUrl/vouchers/my-vouchers';
  static const String useVoucher    = '$baseUrl/vouchers/use';

  // User Profile & Addresses
  static const String userProfile   = '$baseUrl/users/profile';
  static const String userAddresses = '$baseUrl/users/addresses';
}


