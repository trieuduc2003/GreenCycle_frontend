import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../models/voucher_dto.dart';

class VoucherRepository {
  static const _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Lấy danh sách voucher khả dụng trong Reward Store
  Future<List<VoucherDto>> getAvailableVouchers() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.vouchers),
        headers: _baseHeaders,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = (body['data'] as List? ?? []);
        return list.map((item) => VoucherDto.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(_parseError(response, 'Không thể tải danh sách quà tặng'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Thực hiện đổi quà bằng GreenPoints
  Future<RedeemVoucherResponseDto> redeemVoucher(String token, int voucherId) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.redeemVoucher),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'voucherId': voucherId}),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return RedeemVoucherResponseDto.fromJson(body as Map<String, dynamic>);
      } else {
        throw Exception(body['message'] ?? _parseError(response, 'Đổi quà không thành công'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối khi đổi quà: $e');
    }
  }

  /// Lấy danh sách voucher trong "Kho quà của tôi"
  Future<List<UserVoucherDto>> getMyVouchers(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.myVouchers),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = (body['data'] as List? ?? []);
        return list.map((item) => UserVoucherDto.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception(_parseError(response, 'Không thể tải kho quà của bạn'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  /// Đánh dấu đã sử dụng voucher
  Future<bool> useVoucher(String token, int userVoucherId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.useVoucher}/$userVoucherId'),
        headers: {
          ..._baseHeaders,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(_parseError(response, 'Không thể cập nhật trạng thái voucher'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối: $e');
    }
  }

  String _parseError(http.Response response, String fallback) {
    try {
      if (response.body.isEmpty) return fallback;
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) return body['message'];
    } catch (_) {}
    return '$fallback (Mã lỗi: ${response.statusCode})';
  }
}
