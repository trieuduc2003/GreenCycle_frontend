class ApiEndpoints {
  static const String baseUrl      = 'https://10.0.2.2:7031/api';
  static const String hubBaseUrl   = 'https://10.0.2.2:7031'; // SignalR base

  // Auth
  static const String login        = '$baseUrl/auth/login';
  static const String register     = '$baseUrl/auth/register';
  static const String sendOtp      = '$baseUrl/auth/send-otp';
  static const String logout       = '$baseUrl/auth/logout';

  // Wallet
  static const String walletBalance = '$baseUrl/wallet/balance';

  // Orders
  static const String wasteCategories = '$baseUrl/orders/waste-categories';
  static const String createOrder  = '$baseUrl/orders/create';
  static const String myOrders     = '$baseUrl/orders/my-orders';

  // Transactions (Drop-off / Pick-up)
  static const String initiateTransaction = '$baseUrl/transactions/initiate';
  static const String confirmTransaction  = '$baseUrl/transactions/confirm';

  // SignalR Hub
  static const String transactionHub = '$hubBaseUrl/hubs/transaction';

  // Scrap Yards
  static const String nearbyYards  = '$baseUrl/yards/nearby';
  static const String yardDetails  = '$baseUrl/yards';
}
