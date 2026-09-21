class YardChartDataModel {
  final String date;
  final double totalKg;
  final double totalRevenue;

  YardChartDataModel({
    required this.date,
    required this.totalKg,
    required this.totalRevenue,
  });

  factory YardChartDataModel.fromJson(Map<String, dynamic> json) {
    return YardChartDataModel(
      date: json['date'] as String,
      totalKg: (json['totalKg'] as num).toDouble(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
    );
  }
}
