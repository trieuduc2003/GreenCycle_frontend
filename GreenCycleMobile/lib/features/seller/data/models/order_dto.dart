class WasteCategoryDto {
  final int categoryId;
  final String name;
  final String unit; // "kg" or "món"
  final double unitPrice;
  final double? co2ReductionFactor;
  final String? iconName;

  WasteCategoryDto({
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.unitPrice,
    this.co2ReductionFactor,
    this.iconName,
  });

  factory WasteCategoryDto.fromJson(Map<String, dynamic> json) {
    return WasteCategoryDto(
      categoryId: json['categoryId'] ?? 0,
      name: json['name'] ?? '',
      unit: json['unit'] ?? 'kg',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      co2ReductionFactor: (json['co2ReductionFactor'] as num?)?.toDouble(),
      iconName: json['iconName'],
    );
  }
}

class CreateOrderDetailDto {
  final int categoryId;
  final double estimatedWeight;

  CreateOrderDetailDto({
    required this.categoryId,
    required this.estimatedWeight,
  });

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'estimatedWeight': estimatedWeight,
      };
}

class CreateOrderRequestDto {
  final int methodId; // 1: Drop-off, 2: Pick-up
  final int? yardId;
  final int? pickupAddressId;
  final List<CreateOrderDetailDto> details;

  CreateOrderRequestDto({
    required this.methodId,
    this.yardId,
    this.pickupAddressId,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'methodId': methodId,

        'yardId': yardId,
        'pickupAddressId': pickupAddressId,
        'details': details.map((d) => d.toJson()).toList(),
      };
}

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
