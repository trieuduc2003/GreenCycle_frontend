class YardActivityModel {
  final String customerName;
  final String wasteDescription;
  final String pointsAwarded;
  final String timeAgo;

  YardActivityModel({
    required this.customerName,
    required this.wasteDescription,
    required this.pointsAwarded,
    required this.timeAgo,
  });

  factory YardActivityModel.fromJson(Map<String, dynamic> json) {
    return YardActivityModel(
      customerName: json['customerName'] ?? '',
      wasteDescription: json['wasteDescription'] ?? '',
      pointsAwarded: json['pointsAwarded'] ?? '',
      timeAgo: json['timeAgo'] ?? '',
    );
  }
}
