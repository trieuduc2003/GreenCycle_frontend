import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:green_cycle_mobile/core/constants/api_endpoints.dart';
import 'package:green_cycle_mobile/features/seller/data/models/order_dto.dart';
import 'package:green_cycle_mobile/features/seller/data/models/order_history_dto.dart';
import 'package:green_cycle_mobile/features/seller/data/models/order_detail_dto.dart';

class OrderRepository {
  Future<List<WasteCategoryDto>> getWasteCategories() async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.wasteCategories),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List list = body['data'];
          return list.map((item) => WasteCategoryDto.fromJson(item)).toList();
        }
      }
    } catch (_) {}

    // Fallback default categories matching A06 spec if backend API unavailable offline
    return [
      WasteCategoryDto(
        categoryId: 1,
        name: 'Giấy / Carton',
        unit: 'kg',
        unitPrice: 200,
        co2ReductionFactor: 1.2,
        iconName: 'description_outlined',
      ),
      WasteCategoryDto(
        categoryId: 2,
        name: 'Rác điện tử',
        unit: 'món',
        unitPrice: 5000,
        co2ReductionFactor: 2.5,
        iconName: 'devices_outlined',
      ),
      WasteCategoryDto(
        categoryId: 3,
        name: 'Nhựa các loại',
        unit: 'kg',
        unitPrice: 300,
        co2ReductionFactor: 1.5,
        iconName: 'local_drink_outlined',
      ),
      WasteCategoryDto(
        categoryId: 4,
        name: 'Kim loại / Lon',
        unit: 'kg',
        unitPrice: 500,
        co2ReductionFactor: 2.0,
        iconName: 'takeout_dining_outlined',
      ),
    ];
  }

  Future<CreateOrderResponseDto> createOrder(String token, CreateOrderRequestDto request) async {
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.createOrder),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return CreateOrderResponseDto.fromJson(body['data']);
        }
        throw Exception(body['message'] ?? 'Tạo đơn hàng thất bại');
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Tạo đơn hàng thất bại (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Lỗi kết nối máy chủ: $e');
    }
  }
  Future<List<OrderHistoryDto>> getOrderHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.orderHistory),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List list = body['data'];
          return list.map((item) => OrderHistoryDto.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<OrderDetailViewDto?> getOrderDetail(String token, int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.orderDetail}/$orderId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return OrderDetailViewDto.fromJson(body['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
