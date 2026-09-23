class YardActivityModel {
  final String customerName;
  final String wasteDescription;
  final String pointsAwarded;
  final String timeAgo;
  final String orderType;

  YardActivityModel({
    required this.customerName,
    required this.wasteDescription,
    required this.pointsAwarded,
    required this.timeAgo,
    required this.orderType,
  });

  factory YardActivityModel.fromJson(Map<String, dynamic> json) {
    return YardActivityModel(
      customerName: json['customerName'] ?? 'Khách hàng',
      wasteDescription: json['wasteDescription'] ?? '',
      pointsAwarded: json['pointsAwarded'] ?? '0 GP',
      timeAgo: json['timeAgo'] ?? 'Vừa xong',
      orderType: json['orderType'] ?? 'Drop-off',
    );
  }
}
