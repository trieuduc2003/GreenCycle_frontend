import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../yard/presentation/screens/weight_input_screen.dart';
import '../models/yard_stats_model.dart';
import '../models/yard_activity_model.dart';
import '../models/yard_chart_data_model.dart';

class YardRepository {
  /// Lấy chi tiết đơn hàng để Chủ Vựa có thể nhập số liệu cân thực tế
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

  Future<bool> updateStatus({required String token, required bool isOpening}) async {
    final uri = Uri.parse(ApiEndpoints.yardStatus);
    final resp = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(isOpening),
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể cập nhật trạng thái vựa');
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi cập nhật trạng thái!');
    }
    return true;
  }

  Future<Map<String, dynamic>> getProfile({required String token}) async {
    final uri = Uri.parse(ApiEndpoints.yardProfile);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể tải thông tin vựa');
    }

    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi tải dữ liệu vựa!');
    }

    return data['data'];
  }

  Future<bool> updateProfile({
    required String token,
    required String name,
    required String address,
    required String operatingHours,
    double? latitude,
    double? longitude,
  }) async {
    final uri = Uri.parse(ApiEndpoints.yardProfile);
    final resp = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'address': address,
        'operatingHours': operatingHours,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể cập nhật hồ sơ vựa');
    }

    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi cập nhật hồ sơ!');
    }

    return true;
  }

  Future<YardStatsModel> getStats({required String token}) async {
    final uri = Uri.parse(ApiEndpoints.yardStats);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể lấy thống kê');
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi lấy thống kê!');
    }
    return YardStatsModel.fromJson(data['data']);
  }

  Future<List<YardActivityModel>> getRecentActivities({required String token}) async {
    final uri = Uri.parse(ApiEndpoints.yardActivities);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể lấy hoạt động gần đây');
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi lấy hoạt động!');
    }
    
    final list = data['data'] as List;
    return list.map((e) => YardActivityModel.fromJson(e)).toList();
  }

  Future<List<YardChartDataModel>> getChartStats({required String token, int? month, int? year}) async {
    String url = ApiEndpoints.yardStatsChart;
    if (month != null && year != null) {
      url += '?month=$month&year=$year';
    }
    final uri = Uri.parse(url);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể lấy biểu đồ thống kê');
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi lấy biểu đồ!');
    }
    
    final list = data['data'] as List;
    return list.map((e) => YardChartDataModel.fromJson(e)).toList();
  }

  Future<List<dynamic>> getYardOrderHistory({required String token}) async {
    final uri = Uri.parse(ApiEndpoints.yardOrderHistory);
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể lấy lịch sử thu mua');
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi lấy lịch sử thu mua!');
    }
    return data['data'] as List;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PICK-UP ENDPOINTS
  // ─────────────────────────────────────────────────────────────────────────────
  Future<List<dynamic>> getPendingPickupOrders({required String token}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/orders/pickup/pending');
    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      try {
        final errData = jsonDecode(resp.body);
        throw Exception(errData['message'] ?? 'Không thể tải danh sách đơn thu gom (Lỗi ${resp.statusCode})');
      } catch (_) {
        throw Exception('Không thể tải danh sách đơn thu gom (Lỗi ${resp.statusCode})');
      }
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi tải danh sách!');
    }
    
    return data['data'] as List;
  }

  Future<bool> assignPickupOrder({required String token, required int orderId}) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}/orders/$orderId/assign-collector');
    final resp = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode != 200) {
      throw Exception('Không thể nhận đơn này');
    }
    final data = jsonDecode(resp.body);
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Lỗi nhận đơn!');
    }
    
    return true;
  }
}
