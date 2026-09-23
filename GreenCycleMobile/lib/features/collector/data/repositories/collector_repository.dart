import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../models/collector_order_dto.dart';
import '../../../seller/data/models/order_history_dto.dart';
import '../../presentation/screens/collector_weight_input_screen.dart'; // For OrderDetailItem

class CollectorRepository {
  Future<List<CollectorOrderDto>> getPendingPickupOrders({
    required String token,
    double? latitude,
    double? longitude,
  }) async {
    // Nếu có tọa độ, truyền thêm query params để backend tính khoảng cách
    String url = ApiEndpoints.pendingPickupOrders;
    if (latitude != null && longitude != null) {
      url += '?latitude=$latitude&longitude=$longitude';
    }
    final uri = Uri.parse(url);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể tải danh sách đơn chờ');
    }

    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi tải danh sách!');
    }

    final list = data['data'] as List;
    return list.map((e) => CollectorOrderDto.fromJson(e)).toList();
  }

  Future<void> assignCollector({
    required String token,
    required int orderId,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.assignCollectorBase}/$orderId/assign-collector');
    final resp = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      String errMsg = 'Không thể nhận đơn này!';
      if (resp.body.isNotEmpty) {
        try {
          final data = jsonDecode(resp.body);
          errMsg = data['message'] ?? errMsg;
        } catch (_) {}
      }
      throw Exception(errMsg);
    }
  }

  Future<void> updatePickupStatus({
    required String token,
    required int orderId,
    required String status,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.pickupStatusBase}/$orderId/pickup-status?status=$status');
    final resp = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể cập nhật trạng thái đơn!');
    }
  }

  Future<void> updateLiveLocation({
    required String token,
    required int orderId,
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.assignCollectorBase}/$orderId/collector-location');
    final resp = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (resp.statusCode != 200) {
      // Bỏ qua lỗi nhẹ hoặc in log nếu cần, không ném exception làm crash
      print('Failed to update live location: ${resp.body}');
    }
  }

  Future<List<OrderHistoryDto>> getMyOrders({required String token}) async {
    // Dùng chung endpoint order history, backend tự nhận diện role = Collector
    final uri = Uri.parse(ApiEndpoints.orderHistory);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể tải lịch sử đơn hàng');
    }

    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi tải lịch sử!');
    }

    final list = data['data'] as List;
    return list.map((e) => OrderHistoryDto.fromJson(e)).toList();
  }

  /// Lấy chi tiết đơn hàng (dùng lại Model của Yard)
  Future<List<OrderDetailItem>> getOrderDetails({
    required String token,
    required int orderId,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId/details');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể tải chi tiết đơn hàng #$orderId');
    }

    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi tải dữ liệu!');
    }

    final list = data['data'] as List;
    return list.map((e) => OrderDetailItem(
      orderDetailId: e['orderDetailId'] as int,
      categoryName: e['categoryName'] as String,
      unit: e['unit'] as String,
      estimatedWeight: (e['estimatedWeight'] as num).toDouble(),
      unitPrice: (e['unitPrice'] as num).toDouble(),
    )).toList();
  }
}
