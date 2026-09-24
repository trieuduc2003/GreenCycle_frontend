import 'create_order_detail_dto.dart';

class CreateOrderRequestDto {
  final int methodId; // 1: Drop-off, 2: Pick-up
  final int? yardId;
  final int? pickupAddressId;
  final List<CreateOrderDetailDto> details;

  CreateOrderRequestDto({
    required this.methodId,
    this.yardId,
    this.pickupAddressId,
    required this.details,
  });

  Map<String, dynamic> toJson() => {
        'methodId': methodId,
        'yardId': yardId,
        'pickupAddressId': pickupAddressId,
        'details': details.map((d) => d.toJson()).toList(),
      };
}
