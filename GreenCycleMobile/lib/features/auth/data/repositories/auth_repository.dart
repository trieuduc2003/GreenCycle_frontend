import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:green_cycle_mobile/core/constants/api_endpoints.dart';
import 'package:green_cycle_mobile/features/auth/data/models/login_dto.dart';

class AuthRepository {
  // ─── Headers chung ───────────────────────────────────────────────────────
  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ─── ĐĂNG NHẬP ───────────────────────────────────────────────────────────
  /// Đăng nhập bằng Số điện thoại + Mật khẩu
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return LoginResponseDto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseError(response, 'Đăng nhập thất bại'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  // ─── ĐĂNG KÝ - BƯỚC 1: GỬI OTP ──────────────────────────────────────────
  /// Gửi OTP về SĐT để xác thực số điện thoại trước khi đăng ký
  Future<void> sendOtp(String phone) async {
    try {
      final request = SendOtpRequestDto(phone: phone);
      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtp),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(_parseError(response, 'Không thể gửi OTP'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  // ─── ĐĂNG KÝ - BƯỚC 2: TẠO TÀI KHOẢN ───────────────────────────────────
  /// Xác thực OTP và tạo tài khoản mới
  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.register),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return RegisterResponseDto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseError(response, 'Đăng ký thất bại'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  // ─── ĐĂNG XUẤT ───────────────────────────────────────────────────────────
  /// Gửi yêu cầu đăng xuất tới API (nếu token được truyền kèm, thêm Authorization header)
  Future<void> logout([String? token]) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      await http.post(
        Uri.parse(ApiEndpoints.logout),
        headers: headers,
      );
    } catch (_) {
      // Bỏ qua lỗi kết nối khi đăng xuất cục bộ
    }
  }

  // ─── Helper: parse thông báo lỗi từ API ──────────────────────────────────
  String _parseError(http.Response response, String fallback) {
    try {
      if (response.body.isEmpty) return fallback;
      final body = jsonDecode(response.body);
      if (body is Map && body.containsKey('message')) return body['message'];
    } catch (_) {}
    return '$fallback (Mã lỗi: ${response.statusCode})';
  }
}