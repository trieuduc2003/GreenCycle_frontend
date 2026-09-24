class CreateOrderResponseDto {
  final int orderId;
  final int methodId;
  final String methodName;
  final int statusId;
  final String statusName;
  final double totalEstimatedAmount;
  final double platformFee;
  final double netEstimatedAmount;
  final String createdAt;

  CreateOrderResponseDto({
    required this.orderId,
    required this.methodId,
    required this.methodName,
    required this.statusId,
    required this.statusName,
    required this.totalEstimatedAmount,
    required this.platformFee,
    required this.netEstimatedAmount,
    required this.createdAt,
  });

  factory CreateOrderResponseDto.fromJson(Map<String, dynamic> json) {
    return CreateOrderResponseDto(
      orderId: json['orderId'] ?? 0,
      methodId: json['methodId'] ?? 1,
      methodName: json['methodName'] ?? 'Drop-off',
      statusId: json['statusId'] ?? 1,
      statusName: json['statusName'] ?? 'Pending',
      totalEstimatedAmount: (json['totalEstimatedAmount'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      netEstimatedAmount: (json['netEstimatedAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] ?? '',
    );
  }
}
