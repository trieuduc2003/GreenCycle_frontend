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

  /// Lấy lịch sử giao dịch ví — gọi GET /api/wallet/transactions
  Future<List<WalletTransactionDto>> getTransactions(String token, {int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.walletTransactions}?limit=$limit'),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final data = body['data'] as List;
          return data.map((e) => WalletTransactionDto.fromJson(e)).toList();
        }
        throw Exception(body['message'] ?? 'Không thể tải lịch sử giao dịch');
      } else {
        throw Exception(_parseError(response, 'Không thể tải lịch sử giao dịch'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Nạp tiền vào ví
  Future<bool> depositWallet(String token, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.walletDeposit),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(_parseError(response, 'Không thể nạp tiền'));
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
