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
