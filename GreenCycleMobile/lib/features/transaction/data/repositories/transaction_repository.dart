import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../models/transaction_dto.dart';

class TransactionRepository {
  /// Gọi API để Người Bán xác nhận giao dịch sau khi nhận SignalR
  Future<void> confirmTransaction({
    required String token,
    required int orderId,
  }) async {
    final uri = Uri.parse(ApiEndpoints.confirmTransaction);
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'orderId': orderId}),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Xác nhận giao dịch thất bại!');
    }
  }

  /// Gọi API để Chủ Vựa nhập số liệu thực tế → trigger Xác nhận chéo
  Future<void> initiateTransaction({
    required String token,
    required InitiateTransactionRequest request,
  }) async {
    final uri = Uri.parse(ApiEndpoints.initiateTransaction);
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể khởi tạo giao dịch!');
    }
  }

  /// Gọi API để Người Thu Gom (Collector) nhập số liệu thực tế → trigger Xác nhận chéo (Pick-up)
  Future<void> initiatePickupTransaction({
    required String token,
    required InitiateTransactionRequest request,
  }) async {
    final uri = Uri.parse(ApiEndpoints.initiatePickupTransaction);
    final resp = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toJson()),
    );
    final data = jsonDecode(resp.body);
    if (resp.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Không thể khởi tạo giao dịch thu gom!');
    }
  }
}
