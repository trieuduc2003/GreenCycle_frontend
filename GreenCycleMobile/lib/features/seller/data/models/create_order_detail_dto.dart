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
