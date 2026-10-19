import 'actual_weight_dto.dart';

class InitiateTransactionRequest {
  final int orderId;
  final List<ActualWeightDto> actualWeights;
  final bool confirmedOverLimit;

  InitiateTransactionRequest({
    required this.orderId,
    required this.actualWeights,
    this.confirmedOverLimit = false,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'actualWeights': actualWeights.map((e) => e.toJson()).toList(),
        'confirmedOverLimit': confirmedOverLimit,
      };
}
