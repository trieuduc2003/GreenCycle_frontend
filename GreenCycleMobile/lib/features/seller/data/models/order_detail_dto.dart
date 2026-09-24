class OrderDetailViewDto {
  final int orderId;
  final int sellerId;
  final String sellerName;
  final String sellerPhone;
  final int methodId;
  final String methodName;
  final int statusId;
  final String statusName;
  final double totalEstimatedAmount;
  final double? totalActualAmount;
  final double platformFee;
  final double netEstimatedAmount;
  final double? netActualAmount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? scrapYardName;
  final String? scrapYardAddress;
  final String? pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String? collectorName;
  final String? collectorPhone;
  final String? collectorVehicleType;
  final String? collectorLicensePlate;
  final double estimatedCo2ReducedKg;
  final List<OrderItemDetailDto> items;

  OrderDetailViewDto({
    required this.orderId,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.methodId,
    required this.methodName,
    required this.statusId,
    required this.statusName,
    required this.totalEstimatedAmount,
    this.totalActualAmount,
    required this.platformFee,
    required this.netEstimatedAmount,
    this.netActualAmount,
    required this.createdAt,
    this.updatedAt,
    this.scrapYardName,
    this.scrapYardAddress,
    this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.collectorName,
    this.collectorPhone,
    this.collectorVehicleType,
    this.collectorLicensePlate,
    required this.estimatedCo2ReducedKg,
    required this.items,
  });

  factory OrderDetailViewDto.fromJson(Map<String, dynamic> json) {
    return OrderDetailViewDto(
      orderId: json['orderId'] ?? 0,
      sellerId: json['sellerId'] ?? 0,
      sellerName: json['sellerName'] ?? '',
      sellerPhone: json['sellerPhone'] ?? '',
      methodId: json['methodId'] ?? 0,
      methodName: json['methodName'] ?? '',
      statusId: json['statusId'] ?? 0,
      statusName: json['statusName'] ?? '',
      totalEstimatedAmount: (json['totalEstimatedAmount'] as num?)?.toDouble() ?? 0.0,
      totalActualAmount: (json['totalActualAmount'] as num?)?.toDouble(),
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      netEstimatedAmount: (json['netEstimatedAmount'] as num?)?.toDouble() ?? 0.0,
      netActualAmount: (json['netActualAmount'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      scrapYardName: json['scrapYardName'],
      scrapYardAddress: json['scrapYardAddress'],
      pickupAddress: json['pickupAddress'],
      pickupLatitude: (json['pickupLatitude'] as num?)?.toDouble(),
      pickupLongitude: (json['pickupLongitude'] as num?)?.toDouble(),
      collectorName: json['collectorName'],
      collectorPhone: json['collectorPhone'],
      collectorVehicleType: json['collectorVehicleType'],
      collectorLicensePlate: json['collectorLicensePlate'],
      estimatedCo2ReducedKg: (json['estimatedCo2ReducedKg'] as num?)?.toDouble() ?? 0.0,
      items: (json['items'] as List? ?? [])
          .map((item) => OrderItemDetailDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OrderItemDetailDto {
  final int orderDetailId;
  final int categoryId;
  final String categoryName;
  final String unit;
  final double estimatedWeight;
  final double? actualWeight;
  final double unitPrice;
  final double estimatedSubTotal;
  final double? actualSubTotal;
  final double co2ReductionFactor;

  OrderItemDetailDto({
    required this.orderDetailId,
    required this.categoryId,
    required this.categoryName,
    required this.unit,
    required this.estimatedWeight,
    this.actualWeight,
    required this.unitPrice,
    required this.estimatedSubTotal,
    this.actualSubTotal,
    required this.co2ReductionFactor,
  });

  factory OrderItemDetailDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDetailDto(
      orderDetailId: json['orderDetailId'] ?? 0,
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      unit: json['unit'] ?? 'kg',
      estimatedWeight: (json['estimatedWeight'] as num?)?.toDouble() ?? 0.0,
      actualWeight: (json['actualWeight'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      estimatedSubTotal: (json['estimatedSubTotal'] as num?)?.toDouble() ?? 0.0,
      actualSubTotal: (json['actualSubTotal'] as num?)?.toDouble(),
      co2ReductionFactor: (json['co2ReductionFactor'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
