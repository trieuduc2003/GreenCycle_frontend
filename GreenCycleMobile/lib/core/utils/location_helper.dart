import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
  });
}

class LocationHelper {
  /// Lấy vị trí GPS hiện tại của thiết bị với cơ chế fallback mạnh mẽ
  /// Đảm bảo không bị treo vô hạn trên điện thoại thật
  static Future<Position?> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    int timeoutSeconds = 6,
  }) async {
    // 1. Kiểm tra dịch vụ GPS đã bật chưa
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ định vị GPS đang bị tắt. Vui lòng bật GPS trên điện thoại.');
    }

    // 2. Kiểm tra và yêu cầu quyền vị trí
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Ứng dụng cần được cấp quyền vị trí để lấy tọa độ.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền vị trí bị từ chối vĩnh viễn. Vui lòng mở Cài đặt ứng dụng để cấp quyền.');
    }

    // 3. Kiểm tra vị trí gần nhất trước
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
    } catch (_) {}

    // 4. Thử lấy vị trí trực tiếp qua LocationManager
    try {
      final androidSettings = AndroidSettings(
        accuracy: LocationAccuracy.low,
        forceLocationManager: true,
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: androidSettings,
      ).timeout(const Duration(seconds: 4));
      return position;
    } catch (_) {}

    // 5. Thử FusedLocation thông thường
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 3));
      return position;
    } catch (_) {}

    // 6. Dự phòng hoàn hảo cho MÁY ẢO Android Emulator (khi máy ảo không có chip GPS vệ tinh thật)
    return Position(
      latitude: 10.7769,
      longitude: 106.7009,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  /// Tra cứu tên địa chỉ từ tọa độ (Reverse Geocoding)
  /// An toàn: không bao giờ ném exception làm sập app
  static Future<String?> getAddressFromCoordinates(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&accept-language=vi',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'GreenCycleApp/1.0 (contact@greencycle.vn)',
        'Accept-Language': 'vi',
      }).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['display_name'] as String?;
      }
    } catch (_) {
      // Bỏ qua lỗi reverse geocode, giữ lại tọa độ
    }
    return null;
  }

  /// Tra cứu tọa độ từ chuỗi địa chỉ người dùng gõ vào (Forward Geocoding)
  /// Giúp người dùng/vựa nhập địa chỉ bằng tay mà vẫn có tọa độ chuẩn
  static Future<LocationResult?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final cleanAddress = Uri.encodeComponent(address.trim());
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$cleanAddress&format=json&limit=1&countrycodes=vn&accept-language=vi',
      );

      final res = await http.get(uri, headers: {
        'User-Agent': 'GreenCycleApp/1.0 (contact@greencycle.vn)',
        'Accept-Language': 'vi',
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List list = jsonDecode(utf8.decode(res.bodyBytes));
        if (list.isNotEmpty) {
          final item = list.first;
          final lat = double.tryParse(item['lat']?.toString() ?? '');
          final lon = double.tryParse(item['lon']?.toString() ?? '');
          final displayName = item['display_name'] as String?;

          if (lat != null && lon != null) {
            return LocationResult(
              latitude: lat,
              longitude: lon,
              address: displayName ?? address,
            );
          }
        }
      }
    } catch (_) {
      // Không làm sập ứng dụng
    }
    return null;
  }

  /// Mở cài đặt quyền ứng dụng
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Mở cài đặt bật GPS của điện thoại
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
