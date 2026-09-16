import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:green_cycle_mobile/core/constants/api_endpoints.dart';
import 'package:green_cycle_mobile/features/seller/data/models/wallet_dto.dart';

class WalletRepository {
  static const _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Lấy số dư ví — gọi GET /api/wallet/balance với JWT token.
  Future<WalletBalanceDto> getBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.walletBalance),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return WalletBalanceDto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseError(response, 'Không thể lấy số dư ví'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  // Helper: parse thông báo lỗi từ API
  String _parseError(http.Response response, String fallback) {
    try {
      if (response.body.isEmpty) return fallback;
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) return body['message'];
    } catch (_) {}
    return '$fallback (Mã lỗi: ${response.statusCode})';
  }
}
