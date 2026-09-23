class YardChartDataModel {
  final String date;
  final double dropOffKg;
  final double dropOffRevenue;
  final double pickUpKg;
  final double pickUpRevenue;
  final double totalKg;
  final double totalRevenue;

  YardChartDataModel({
    required this.date,
    required this.dropOffKg,
    required this.dropOffRevenue,
    required this.pickUpKg,
    required this.pickUpRevenue,
    required this.totalKg,
    required this.totalRevenue,
  });

  factory YardChartDataModel.fromJson(Map<String, dynamic> json) {
    return YardChartDataModel(
      date: json['date'] as String,
      dropOffKg: (json['dropOffKg'] ?? 0).toDouble(),
      dropOffRevenue: (json['dropOffRevenue'] ?? 0).toDouble(),
      pickUpKg: (json['pickUpKg'] ?? 0).toDouble(),
      pickUpRevenue: (json['pickUpRevenue'] ?? 0).toDouble(),
      totalKg: (json['totalKg'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
