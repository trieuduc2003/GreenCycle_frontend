class OrderHistoryDto {
  final int orderId;
  final String methodName;
  final String statusName;
  final double totalEstimatedAmount;
  final double platformFee;
  final DateTime createdAt;
  final int itemsCount;

  OrderHistoryDto({
    required this.orderId,
    required this.methodName,
    required this.statusName,
    required this.totalEstimatedAmount,
    required this.platformFee,
    required this.createdAt,
    required this.itemsCount,
  });

  factory OrderHistoryDto.fromJson(Map<String, dynamic> json) {
    return OrderHistoryDto(
      orderId: json['orderId'] as int,
      methodName: json['methodName'] as String,
      statusName: json['statusName'] as String,
      totalEstimatedAmount: (json['totalEstimatedAmount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      itemsCount: json['itemsCount'] as int,
    );
  }
}
