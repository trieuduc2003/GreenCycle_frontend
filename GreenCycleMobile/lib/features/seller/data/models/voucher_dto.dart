class VoucherDto {
  final int voucherId;
  final String title;
  final String? description;
  final double pointCost;
  final double discountValue;
  final int? quantity;
  final bool isActive;
  final DateTime expiredAt;
  final String category;

  VoucherDto({
    required this.voucherId,
    required this.title,
    this.description,
    required this.pointCost,
    required this.discountValue,
    this.quantity,
    required this.isActive,
    required this.expiredAt,
    required this.category,
  });

  factory VoucherDto.fromJson(Map<String, dynamic> json) {
    return VoucherDto(
      voucherId: json['voucherId'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      pointCost: (json['pointCost'] as num?)?.toDouble() ?? 0.0,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      quantity: json['quantity'] as int?,
      isActive: json['isActive'] ?? true,
      expiredAt: json['expiredAt'] != null
          ? DateTime.tryParse(json['expiredAt']) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      category: json['category'] ?? 'Khác',
    );
  }
}

class UserVoucherDto {
  final int userVoucherId;
  final int userId;
  final int voucherId;
  final String voucherCode;
  final String title;
  final String? description;
  final double pointCost;
  final double discountValue;
  final bool isUsed;
  final DateTime? receivedAt;
  final DateTime? usedAt;
  final DateTime expiredAt;
  final String category;

  UserVoucherDto({
    required this.userVoucherId,
    required this.userId,
    required this.voucherId,
    required this.voucherCode,
    required this.title,
    this.description,
    required this.pointCost,
    required this.discountValue,
    required this.isUsed,
    this.receivedAt,
    this.usedAt,
    required this.expiredAt,
    required this.category,
  });

  bool get isExpired => DateTime.now().isAfter(expiredAt);

  factory UserVoucherDto.fromJson(Map<String, dynamic> json) {
    return UserVoucherDto(
      userVoucherId: json['userVoucherId'] ?? 0,
      userId: json['userId'] ?? 0,
      voucherId: json['voucherId'] ?? 0,
      voucherCode: json['voucherCode'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      pointCost: (json['pointCost'] as num?)?.toDouble() ?? 0.0,
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      isUsed: json['isUsed'] ?? false,
      receivedAt: json['receivedAt'] != null ? DateTime.tryParse(json['receivedAt']) : null,
      usedAt: json['usedAt'] != null ? DateTime.tryParse(json['usedAt']) : null,
      expiredAt: json['expiredAt'] != null
          ? DateTime.tryParse(json['expiredAt']) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      category: json['category'] ?? 'Khác',
    );
  }
}

class RedeemVoucherResponseDto {
  final bool success;
  final String message;
  final UserVoucherDto? userVoucher;
  final double remainingPoints;
  final double treesSaved;
  final double co2ReducedKg;

  RedeemVoucherResponseDto({
    required this.success,
    required this.message,
    this.userVoucher,
    required this.remainingPoints,
    required this.treesSaved,
    required this.co2ReducedKg,
  });

  factory RedeemVoucherResponseDto.fromJson(Map<String, dynamic> json) {
    return RedeemVoucherResponseDto(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      remainingPoints: (json['remainingPoints'] as num?)?.toDouble() ?? 0.0,
      treesSaved: (json['treesSaved'] as num?)?.toDouble() ?? 0.0,
      co2ReducedKg: (json['co2ReducedKg'] as num?)?.toDouble() ?? 0.0,
      userVoucher: json['userVoucher'] != null
          ? UserVoucherDto.fromJson(json['userVoucher'] as Map<String, dynamic>)
          : null,
    );
  }
}
