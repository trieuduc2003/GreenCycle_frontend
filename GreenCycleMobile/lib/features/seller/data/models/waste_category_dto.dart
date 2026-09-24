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
