/// Model class đại diện cho một Vựa rác trả về từ API.
/// Mỗi trường (field) tương ứng với một key trong JSON.
class ScrapYardModel {
  /// ID duy nhất của vựa trong database
  final int yardId;

  /// Tên vựa rác (ví dụ: "Vựa Phú Nhuận")
  final String name;

  /// Địa chỉ đầy đủ của vựa
  final String address;

  /// Tọa độ vĩ độ (latitude) của vựa — dùng để đặt marker và chỉ đường
  final double latitude;

  /// Tọa độ kinh độ (longitude) của vựa — dùng để đặt marker và chỉ đường
  final double longitude;

  /// Khoảng cách từ người dùng đến vựa, đơn vị mét (ví dụ: 1200.5)
  final double distanceInMeters;

  /// Trạng thái mở/đóng cửa (true = đang mở)
  final bool isOpening;

  /// Giờ hoạt động (ví dụ: "7:00 - 18:00")
  final String? operatingHours;

  /// Đánh giá trung bình của vựa (0.0 - 5.0)
  final double ranking;

  /// Constructor — tất cả các trường bắt buộc
  ScrapYardModel({
    required this.yardId,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceInMeters,
    required this.isOpening,
    this.operatingHours,
    required this.ranking,
  });

  /// Factory constructor để tạo object từ một Map JSON
  /// Sử dụng khi decode response từ API:
  ///   final yard = ScrapYardModel.fromJson(jsonObject);
  factory ScrapYardModel.fromJson(Map<String, dynamic> json) {
    return ScrapYardModel(
      yardId: json['yardId'] as int,
      name: json['scrapYardName'] as String? ?? 'Vựa không tên',
      address: json['address'] as String? ?? 'Không có địa chỉ',
      // Tọa độ được lưu trong object "location" hoặc trực tiếp
      latitude: _parseDouble(json['latitude'] ?? json['location']?['latitude']),
      longitude: _parseDouble(json['longitude'] ?? json['location']?['longitude']),
      distanceInMeters: _parseDouble(json['distanceInMeters']),
      isOpening: json['isOpening'] as bool? ?? false,
      operatingHours: json['operatingHours'] as String?,
      ranking: _parseDouble(json['ranking']),
    );
  }

  /// Helper tĩnh: parse an toàn các kiểu số khác nhau (int, double, String)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Getter tiện ích: trả về khoảng cách dạng String đẹp
  /// Ví dụ: 1200m → "1.2 km", 800m → "800 m"
  String get distanceFormatted {
    if (distanceInMeters >= 1000) {
      final km = distanceInMeters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${distanceInMeters.toInt()} m';
  }
}
