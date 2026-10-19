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

  // ─── ĐÁNH THỨC SERVER (Cold-start Warmup) ─────────────────────────────────
  /// Ping nhẹ nhàng endpoint health để Render thức giấc từ trạng thái Sleep
  Future<void> preWarmBackend() async {
    try {
      await http.get(Uri.parse(ApiEndpoints.health)).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Bỏ qua lỗi vì đây chỉ là background ping đánh thức máy chủ
    }
  }

  // ─── ĐĂNG NHẬP ───────────────────────────────────────────────────────────
  /// Đăng nhập bằng Số điện thoại + Mật khẩu (Timeout 60s đối phó Render cold-start)
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Kết nối máy chủ bị quá hạn. Máy chủ có thể đang khởi động lại, vui lòng thử lại sau vài giây.'),
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

  // ─── ĐĂNG NHẬP GOOGLE ───────────────────────────────────────────────────
  /// Đăng nhập bằng ID Token từ Google OAuth (Timeout 60s đối phó Render cold-start)
  Future<LoginResponseDto> googleLogin(String idToken, {int? roleId}) async {
    try {
      final request = GoogleLoginRequestDto(idToken: idToken, roleId: roleId);
      final response = await http.post(
        Uri.parse(ApiEndpoints.googleLogin),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Kết nối máy chủ bị quá hạn do máy chủ đang khởi động lại lần đầu. Vui lòng thử lại.'),
      );

      if (response.statusCode == 200) {
        return LoginResponseDto.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(_parseError(response, 'Đăng nhập bằng Google thất bại'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  // ─── ĐĂNG KÝ - BƯỚC 1: GỬI OTP QUA EMAIL ────────────────────────────────
  /// Gửi OTP về Email để xác thực trước khi đăng ký
  Future<void> sendOtp({String? email, String? phone}) async {
    try {
      final request = SendOtpRequestDto(email: email, phone: phone);
      final response = await http.post(
        Uri.parse(ApiEndpoints.sendOtp),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Gửi mã OTP quá hạn. Vui lòng thử lại.'),
      );

      if (response.statusCode != 200) {
        throw Exception(_parseError(response, 'Không thể gửi mã OTP'));
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
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Đăng ký tài khoản quá hạn. Vui lòng thử lại.'),
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

  // ─── QUÊN MẬT KHẨU - GỬI OTP EMAIL ──────────────────────────────────────
  Future<void> forgotPasswordSendOtp(String email) async {
    try {
      final request = ForgotPasswordOtpRequestDto(email: email);
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgotPasswordSendOtp),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Yêu cầu gửi OTP quá hạn. Vui lòng thử lại.'),
      );

      if (response.statusCode != 200) {
        throw Exception(_parseError(response, 'Không thể gửi mã OTP'));
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }

  // ─── QUÊN MẬT KHẨU - ĐẶT LẠI MẬT KHẨU ─────────────────────────────────
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final request = ResetPasswordRequestDto(
        email: email,
        otpCode: otpCode,
        newPassword: newPassword,
      );
      final response = await http.post(
        Uri.parse(ApiEndpoints.forgotPasswordReset),
        headers: _headers,
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Đặt lại mật khẩu quá hạn. Vui lòng thử lại.'),
      );

      if (response.statusCode != 200) {
        throw Exception(_parseError(response, 'Không thể đặt lại mật khẩu'));
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