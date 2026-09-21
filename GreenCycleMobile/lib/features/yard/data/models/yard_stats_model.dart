class YardStatsModel {
  final int totalCustomers;
  final double totalKgCollected;
  final double totalRevenue;

  YardStatsModel({
    required this.totalCustomers,
    required this.totalKgCollected,
    required this.totalRevenue,
  });

  factory YardStatsModel.fromJson(Map<String, dynamic> json) {
    return YardStatsModel(
      totalCustomers: json['totalCustomers'] ?? 0,
      totalKgCollected: (json['totalKgCollected'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
