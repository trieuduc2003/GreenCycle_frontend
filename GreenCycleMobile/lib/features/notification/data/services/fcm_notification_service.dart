import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';

class FcmNotificationService {
  FcmNotificationService._internal();
  static final FcmNotificationService instance = FcmNotificationService._internal();

  String? _currentFcmToken;
  String? get currentFcmToken => _currentFcmToken;

  /// Khởi tạo và đăng ký FCM Token với hệ thống Backend
  Future<void> initializeAndRegisterToken({required String authToken}) async {
    try {
      // Trong môi trường thực tế (khi có file google-services.json từ Firebase Console):
      // final token = await FirebaseMessaging.instance.getToken();
      // Ở giai đoạn này, tạo token giả lập định danh thiết bị độc bản để liên kết user
      _currentFcmToken ??= 'fcm_dev_${DateTime.now().millisecondsSinceEpoch}_device';

      final uri = Uri.parse('${ApiEndpoints.baseUrl}/users/fcm-token');
      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': _currentFcmToken,
        }),
      );

      if (resp.statusCode == 200) {
        print('FCM Token registered successfully with backend: $_currentFcmToken');
      } else {
        print('FCM Token registration failed: ${resp.body}');
      }
    } catch (e) {
      print('Error registering FCM Token: $e');
    }
  }

  /// Kích hoạt chuông và rung thông báo khi nhận push notification
  void triggerNotificationSoundAndVibration() {
    try {
      HapticFeedback.vibrate();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
