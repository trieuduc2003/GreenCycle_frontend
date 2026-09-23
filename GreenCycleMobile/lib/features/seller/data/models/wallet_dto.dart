// ─── Wallet Balance Response ──────────────────────────────────────────────
class WalletBalanceDto {
  final int walletId;
  final String walletType;
  final String currency;
  final double balance;
  final double balanceInVnd;
  final DateTime? lastUpdated;

  WalletBalanceDto({
    required this.walletId,
    required this.walletType,
    required this.currency,
    required this.balance,
    required this.balanceInVnd,
    this.lastUpdated,
  });

  factory WalletBalanceDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return WalletBalanceDto(
      walletId: data['walletId'] ?? 0,
      walletType: data['walletType'] ?? '',
      currency: data['currency'] ?? 'GP',
      balance: (data['balance'] ?? 0).toDouble(),
      balanceInVnd: (data['balanceInVnd'] ?? 0).toDouble(),
      lastUpdated: data['lastUpdated'] != null
          ? DateTime.tryParse(data['lastUpdated'])
          : null,
    );
  }
}

// ─── Wallet Transaction Response ──────────────────────────────────────────
class WalletTransactionDto {
  final int transactionId;
  final double amount;
  final String transactionType;
  final String description;
  final DateTime? createdAt;
  final int? referenceOrderId;

  WalletTransactionDto({
    required this.transactionId,
    required this.amount,
    required this.transactionType,
    required this.description,
    this.createdAt,
    this.referenceOrderId,
  });

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) {
    return WalletTransactionDto(
      transactionId: json['transactionId'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      transactionType: json['transactionType'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      referenceOrderId: json['referenceOrderId'],
    );
  }
}
