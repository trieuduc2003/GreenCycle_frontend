// ─── Đăng nhập ───────────────────────────────────────
class LoginRequestDto {
  final String phone;
  final String password;

  LoginRequestDto({required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'password': password,
  };
}

class LoginResponseDto {
  final int userId;
  final String token;
  final String fullName;
  final String roleName;

  LoginResponseDto({
    required this.userId,
    required this.token,
    required this.fullName,
    required this.roleName,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return LoginResponseDto(
      userId: data['userId'] ?? 0,
      token: data['token'] ?? '',
      fullName: data['fullName'] ?? '',
      roleName: data['roleName'] ?? '',
    );
  }
}

// ─── Gửi OTP (Bước 1 đăng ký) ───────────────────────
class SendOtpRequestDto {
  final String phone;

  SendOtpRequestDto({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

// ─── Đăng ký (Bước 2 — kèm OTP) ─────────────────────
class RegisterRequestDto {
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final int roleId;
  final String otpCode;

  RegisterRequestDto({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
    required this.roleId,
    required this.otpCode,
  });

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'password': password,
    'roleId': roleId,
    'otpCode': otpCode,
  };
}

class RegisterResponseDto {
  final int userId;
  final String token;
  final String fullName;
  final String roleName;

  RegisterResponseDto({
    required this.userId,
    required this.token,
    required this.fullName,
    required this.roleName,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return RegisterResponseDto(
      userId: data['userId'] ?? 0,
      token: data['token'] ?? '',
      fullName: data['fullName'] ?? '',
      roleName: data['roleName'] ?? '',
    );
  }
}