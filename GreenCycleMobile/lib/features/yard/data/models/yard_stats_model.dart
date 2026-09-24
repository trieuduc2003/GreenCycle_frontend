class YardStatsModel {
  final int totalCustomers;
  final double dropOffKg;
  final double dropOffRevenue;
  final double pickUpKg;
  final double pickUpRevenue;
  final double totalKgCollected;
  final double totalRevenue;

  YardStatsModel({
    required this.totalCustomers,
    required this.dropOffKg,
    required this.dropOffRevenue,
    required this.pickUpKg,
    required this.pickUpRevenue,
    required this.totalKgCollected,
    required this.totalRevenue,
  });

  factory YardStatsModel.fromJson(Map<String, dynamic> json) {
    return YardStatsModel(
      totalCustomers: json['totalCustomers'] ?? 0,
      dropOffKg: (json['dropOffKg'] ?? 0).toDouble(),
      dropOffRevenue: (json['dropOffRevenue'] ?? 0).toDouble(),
      pickUpKg: (json['pickUpKg'] ?? 0).toDouble(),
      pickUpRevenue: (json['pickUpRevenue'] ?? 0).toDouble(),
      totalKgCollected: (json['totalKgCollected'] ?? 0).toDouble(),
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
    );
  }
}
