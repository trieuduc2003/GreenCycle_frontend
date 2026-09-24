import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class UserProfileModel {
  final int userId;
  final String fullName;
  final String phone;
  final String? email;
  final String roleName;
  final DateTime? createdAt;

  UserProfileModel({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.email,
    required this.roleName,
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['userId'] ?? 0,
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      roleName: json['roleName'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  UserProfileModel copyWith({String? fullName, String? phone, String? email}) {
    return UserProfileModel(
      userId: userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      roleName: roleName,
      createdAt: createdAt,
    );
  }
}

class UserAddressModel {
  final int addressId;
  final String? addressLabel;
  final String fullAddress;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  UserAddressModel({
    required this.addressId,
    this.addressLabel,
    required this.fullAddress,
    required this.isDefault,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      addressId: json['addressId'] ?? 0,
      addressLabel: json['addressLabel'],
      fullAddress: json['fullAddress'] ?? '',
      isDefault: json['isDefault'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }
}

// ─── Repository ───────────────────────────────────────────────────────────────

class UserRepository {
  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  String _parseError(http.Response res, String fallback) {
    try {
      if (res.body.isEmpty) return fallback;
      final body = jsonDecode(res.body);
      if (body is Map && body.containsKey('message')) return body['message'];
    } catch (_) {}
    return '$fallback (Mã lỗi: ${res.statusCode})';
  }

  // ── Lấy hồ sơ cá nhân ─────────────────────────────────────────────────────
  Future<UserProfileModel> getProfile(String token) async {
    final res = await http.get(
      Uri.parse(ApiEndpoints.userProfile),
      headers: _authHeaders(token),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return UserProfileModel.fromJson(body['data'] ?? body);
    }
    throw Exception(_parseError(res, 'Không thể tải thông tin hồ sơ'));
  }

  // ── Cập nhật hồ sơ cá nhân ────────────────────────────────────────────────
  Future<UserProfileModel> updateProfile(
      String token, {required String fullName, String? phone, String? email}) async {
    final res = await http.put(
      Uri.parse(ApiEndpoints.userProfile),
      headers: _authHeaders(token),
      body: jsonEncode({
        'fullName': fullName,
        if (phone != null) 'phone': phone,
        'email': email,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return UserProfileModel.fromJson(body['data'] ?? body);
    }
    throw Exception(_parseError(res, 'Không thể cập nhật hồ sơ'));
  }

  // ── Danh sách địa chỉ ────────────────────────────────────────────────────
  Future<List<UserAddressModel>> getAddresses(String token) async {
    final res = await http.get(
      Uri.parse(ApiEndpoints.userAddresses),
      headers: _authHeaders(token),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body['data'] as List<dynamic>? ?? [];
      return list.map((e) => UserAddressModel.fromJson(e)).toList();
    }
    throw Exception(_parseError(res, 'Không thể tải danh sách địa chỉ'));
  }

  // ── Thêm địa chỉ ─────────────────────────────────────────────────────────
  Future<UserAddressModel> addAddress(
      String token, {
      required String fullAddress,
      String? label,
      double lat = 10.7769,
      double lng = 106.7009,
      bool isDefault = false,
  }) async {
    final res = await http.post(
      Uri.parse(ApiEndpoints.userAddresses),
      headers: _authHeaders(token),
      body: jsonEncode({
        'fullAddress': fullAddress,
        'addressLabel': label,
        'latitude': lat,
        'longitude': lng,
        'isDefault': isDefault,
      }),
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return UserAddressModel.fromJson(body['data'] ?? body);
    }
    throw Exception(_parseError(res, 'Không thể thêm địa chỉ'));
  }

  // ── Xóa địa chỉ ──────────────────────────────────────────────────────────
  Future<void> deleteAddress(String token, int addressId) async {
    final res = await http.delete(
      Uri.parse('${ApiEndpoints.userAddresses}/$addressId'),
      headers: _authHeaders(token),
    );
    if (res.statusCode != 200) {
      throw Exception(_parseError(res, 'Không thể xóa địa chỉ'));
    }
  }

  // ── Đặt địa chỉ mặc định ─────────────────────────────────────────────────
  Future<void> setDefaultAddress(String token, int addressId) async {
    final res = await http.patch(
      Uri.parse('${ApiEndpoints.userAddresses}/$addressId/set-default'),
      headers: _authHeaders(token),
    );
    if (res.statusCode != 200) {
      throw Exception(_parseError(res, 'Không thể đặt địa chỉ mặc định'));
    }
  }
}
