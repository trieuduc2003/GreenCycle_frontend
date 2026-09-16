import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../yard/presentation/screens/weight_input_screen.dart';

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
    )).toList();
  }
}
