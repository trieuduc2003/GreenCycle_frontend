class OrderHistoryDto {
  final int orderId;
  final String methodName;
  final String statusName;
  final double totalEstimatedAmount;
  final double platformFee;
  final DateTime createdAt;
  final int itemsCount;
  final String? sellerName;
  final String? sellerPhone;
  final String? pickupAddress;

  OrderHistoryDto({
    required this.orderId,
    required this.methodName,
    required this.statusName,
    required this.totalEstimatedAmount,
    required this.platformFee,
    required this.createdAt,
    required this.itemsCount,
    this.sellerName,
    this.sellerPhone,
    this.pickupAddress,
  });

  factory OrderHistoryDto.fromJson(Map<String, dynamic> json) {
    return OrderHistoryDto(
      orderId: json['orderId'] as int,
      methodName: json['methodName'] as String? ?? '',
      statusName: json['statusName'] as String? ?? '',
      totalEstimatedAmount: (json['totalEstimatedAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      itemsCount: json['itemsCount'] as int? ?? 0,
      sellerName: json['sellerName'] as String?,
      sellerPhone: json['sellerPhone'] as String?,
      pickupAddress: json['pickupAddress'] as String?,
    );
  }
}
