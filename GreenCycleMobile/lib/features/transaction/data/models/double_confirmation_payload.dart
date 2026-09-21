class DoubleConfirmationPayload {
  final int orderId;

  /// methodId: 1 = Drop-off, 2 = Pick-up
  final int methodId;

  /// Tên Vựa rác (cho Drop-off)
  final String yardName;

  /// Tên tài xế (cho Pick-up, nullable)
  final String? collectorName;

  /// SĐT tài xế (cho Pick-up, nullable)
  final String? collectorPhone;

  final double totalActualAmount;
  final double platformFee;
  final double netGreenPoints;

  DoubleConfirmationPayload({
    required this.orderId,
    required this.methodId,
    required this.yardName,
    this.collectorName,
    this.collectorPhone,
    required this.totalActualAmount,
    required this.platformFee,
    required this.netGreenPoints,
  });

  bool get isPickup => methodId == 2;

  /// Tên bên đối tác (Vựa hoặc Tài xế) để hiển thị trong dialog
  String get partnerDisplayName {
    if (isPickup) return collectorName ?? 'Tài xế GreenCycle';
    return yardName.isNotEmpty ? yardName : 'Vựa thu mua GreenCycle';
  }

  factory DoubleConfirmationPayload.fromJson(Map<String, dynamic> json) {
    return DoubleConfirmationPayload(
      orderId: json['orderId'] as int,
      methodId: (json['methodId'] as num?)?.toInt() ?? 1,
      yardName: (json['yardName'] as String?) ?? '',
      collectorName: json['collectorName'] as String?,
      collectorPhone: json['collectorPhone'] as String?,
      totalActualAmount: (json['totalActualAmount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      netGreenPoints: (json['netGreenPoints'] as num).toDouble(),
    );
  }
}
