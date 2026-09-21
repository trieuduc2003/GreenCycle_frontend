import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:green_cycle_mobile/core/constants/api_endpoints.dart';
import '../models/scrap_yard_model.dart';

/// Service layer chuyên trách gọi API liên quan đến Vựa rác.
/// Tách biệt logic gọi mạng khỏi UI để dễ test và bảo trì.
class YardApiService {
  /// Lấy danh sách vựa rác gần vị trí người dùng.
  ///
  /// [token] — JWT token của người dùng đã đăng nhập (Authorization header).
  /// [latitude] — Vĩ độ hiện tại của người dùng.
  /// [longitude] — Kinh độ hiện tại của người dùng.
  ///
  /// Trả về danh sách tối đa 10 [ScrapYardModel] trong bán kính 5km.
  /// Ném [Exception] nếu lỗi mạng hoặc server trả lỗi.
  Future<List<ScrapYardModel>> getNearbyYards({
    required String token,
    required double latitude,
    required double longitude,
  }) async {
    // Xây dựng URL với query parameters tọa độ
    final uri = Uri.parse(ApiEndpoints.nearbyYards).replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': '50000000', // bán kính khổng lồ để luôn tìm thấy vựa test
        'limit': '10',    // tối đa 10 kết quả
      },
    );

    try {
      // Gửi HTTP GET request với Bearer token
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 15), // timeout 15 giây
        onTimeout: () => throw Exception('Kết nối máy chủ bị timeout'),
      );

      if (response.statusCode == 200) {
        // Parse body JSON
        final body = jsonDecode(response.body);

        // API trả về định dạng { success: true, data: [...] }
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'];

          // Chuyển mỗi item JSON → ScrapYardModel
          return list
              .map((item) => ScrapYardModel.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        // Không tìm thấy vựa nào trong bán kính → trả về list rỗng
        return [];
      } else {
        // Lỗi server — ném exception để UI xử lý
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Lỗi máy chủ (${response.statusCode})');
      }
    } on Exception {
      rethrow; // Re-throw để màn hình hiển thị thông báo lỗi
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }

  /// Cập nhật vựa rác (Yard) cho đơn hàng (Drop-off).
  Future<void> selectYardForOrder({
    required String token,
    required int orderId,
    required int yardId,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId/select-yard');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(yardId),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Kết nối máy chủ bị timeout'),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) return;
        throw Exception(body['message'] ?? 'Lỗi khi chọn vựa.');
      } else {
        throw Exception('Lỗi máy chủ (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Lỗi kết nối: $e');
    }
  }
}
