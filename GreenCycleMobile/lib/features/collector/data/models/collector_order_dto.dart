class CollectorOrderDto {
  final int orderId;
  final String sellerName;
  final String? sellerPhone;
  final String address;
  final double latitude;
  final double longitude;
  final double totalEstimatedWeight;
  final String status;
  final DateTime createdAt;
  final double? distance;

  CollectorOrderDto({
    required this.orderId,
    required this.sellerName,
    this.sellerPhone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.totalEstimatedWeight,
    required this.status,
    required this.createdAt,
    this.distance,
  });

  factory CollectorOrderDto.fromJson(Map<String, dynamic> json) {
    return CollectorOrderDto(
      orderId: json['orderId'] as int,
      sellerName: json['sellerName'] as String? ?? 'Khách hàng',
      sellerPhone: json['sellerPhone'] as String?,
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      totalEstimatedWeight: (json['totalEstimatedWeight'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'Pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : DateTime.now(),
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }
}
