import 'actual_weight_dto.dart';

class InitiateTransactionRequest {
  final int orderId;
  final List<ActualWeightDto> actualWeights;

  InitiateTransactionRequest({required this.orderId, required this.actualWeights});

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'actualWeights': actualWeights.map((e) => e.toJson()).toList(),
      };
}
