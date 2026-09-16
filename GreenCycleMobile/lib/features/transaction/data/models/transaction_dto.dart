class DoubleConfirmationPayload {
  final int orderId;
  final String yardName;
  final double totalActualAmount;
  final double platformFee;
  final double netGreenPoints;

  DoubleConfirmationPayload({
    required this.orderId,
    required this.yardName,
    required this.totalActualAmount,
    required this.platformFee,
    required this.netGreenPoints,
  });

  factory DoubleConfirmationPayload.fromJson(Map<String, dynamic> json) {
    return DoubleConfirmationPayload(
      orderId: json['orderId'] as int,
      yardName: json['yardName'] as String,
      totalActualAmount: (json['totalActualAmount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      netGreenPoints: (json['netGreenPoints'] as num).toDouble(),
    );
  }
}

class ActualWeightDto {
  final int orderDetailId;
  final double actualWeight;

  ActualWeightDto({required this.orderDetailId, required this.actualWeight});

  Map<String, dynamic> toJson() => {
        'orderDetailId': orderDetailId,
        'actualWeight': actualWeight,
      };
}

class InitiateTransactionRequest {
  final int orderId;
  final List<ActualWeightDto> actualWeights;

  InitiateTransactionRequest({required this.orderId, required this.actualWeights});

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'actualWeights': actualWeights.map((e) => e.toJson()).toList(),
      };
}
