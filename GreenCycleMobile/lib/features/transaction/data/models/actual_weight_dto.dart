class ActualWeightDto {
  final int orderDetailId;
  final double actualWeight;

  ActualWeightDto({required this.orderDetailId, required this.actualWeight});

  Map<String, dynamic> toJson() => {
        'orderDetailId': orderDetailId,
        'actualWeight': actualWeight,
      };
}
