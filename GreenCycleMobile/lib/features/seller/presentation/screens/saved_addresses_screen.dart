import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/user_repository.dart';

/// Màn hình Địa chỉ đã lưu — xem, thêm thủ công, thêm từ GPS, xóa, đặt mặc định.
class SavedAddressesScreen extends StatefulWidget {
  final String token;

  const SavedAddressesScreen({super.key, required this.token});

  // ignore: library_private_types_in_public_api
  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _repo = UserRepository();
  List<UserAddressModel> _addresses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  // ─── Load danh sách địa chỉ ───────────────────────────────────────────────
  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _repo.getAddresses(widget.token);
      if (mounted) {
        setState(() {
          _addresses = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // ─── Xóa địa chỉ ─────────────────────────────────────────────────────────
  Future<void> _deleteAddress(int addressId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa địa chỉ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa địa chỉ này không?',
          style: TextStyle(fontSize: 14, color: Color(0xFF4A5D50)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy',
                style: TextStyle(color: Color(0xFF7A8B80))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repo.deleteAddress(widget.token, addressId);
      _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack('Đã xóa địa chỉ'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack(e.toString().replaceAll('Exception: ', ''), isError: true),
        );
      }
    }
  }

  // ─── Đặt mặc định ────────────────────────────────────────────────────────
  Future<void> _setDefault(int addressId) async {
    try {
      await _repo.setDefaultAddress(widget.token, addressId);
      _loadAddresses();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snack(e.toString().replaceAll('Exception: ', ''), isError: true),
        );
      }
    }
  }

  // ─── GPS: Xin quyền & lấy vị trí ────────────────────────────────────────
  Future<Position?> _getGpsPosition() async {
    // Kiểm tra dịch vụ location
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          'Vui lòng bật dịch vụ định vị trên điện thoại!',
          isError: true,
        ));
      }
      return null;
    }

    // Kiểm tra / xin quyền
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        final openSettings =
            permission == LocationPermission.deniedForever;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(openSettings
                ? 'Quyền vị trí bị từ chối. Vui lòng bật trong Cài đặt.'
                : 'Ứng dụng cần quyền truy cập vị trí.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            action: openSettings
                ? SnackBarAction(
                    label: 'Cài đặt',
                    textColor: Colors.white,
                    onPressed: () => Geolocator.openAppSettings(),
                  )
                : null,
          ),
        );
      }
      return null;
    }

    // Dùng Future.timeout thay cho timeLimit trong LocationSettings
    // vì timeLimit không ổn định trên một số thiết bị Android
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw Exception(
          'Hết thời gian lấy vị trí. Vui lòng kiểm tra GPS và thử lại.'),
    );
  }

  // ─── Reverse Geocode bằng Nominatim (OpenStreetMap — miễn phí) ───────────
  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lng&format=json&accept-language=vi',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'GreenCycleApp/1.0 (contact@greencycle.vn)',
        'Accept-Language': 'vi',
      });
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        return (json['display_name'] as String?) ??
            '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  // ─── Bắt đầu flow GPS ────────────────────────────────────────────────────
  Future<void> _addFromGps() async {
    bool dialogShown = false;

    // Hiện loading dialog
    if (mounted) {
      dialogShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text('Đang lấy vị trí GPS...',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Vui lòng chờ trong giây lát',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF7A8B80))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Position? position;
    try {
      position = await _getGpsPosition();
    } finally {
      // ĐẢM BẢO luôn đóng dialog dù thành công hay lỗi
      if (dialogShown && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (position == null) return;

    // Reverse geocode
    try {
      final address =
          await _reverseGeocode(position.latitude, position.longitude);
      if (mounted) {
        _showAddSheet(
          prefillAddress: address,
          prefillLat: position.latitude,
          prefillLng: position.longitude,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_snack(
          'Lỗi lấy vị trí: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        ));
      }
    }
  }

  // ─── Bottom sheet thêm địa chỉ ──────────────────────────────────────────
  void _showAddSheet({
    String? prefillAddress,
    double? prefillLat,
    double? prefillLng,
  }) {
    final addressCtrl =
        TextEditingController(text: prefillAddress ?? '');
    final labelCtrl = TextEditingController();
    bool isDefault = false;
    bool isSaving = false;
    bool fromGps = prefillLat != null && prefillLng != null;
    double lat = prefillLat ?? 10.7769;
    double lng = prefillLng ?? 106.7009;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tiêu đề + badge GPS
                  Row(
                    children: [
                      const Text(
                        'Thêm địa chỉ mới',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2E22)),
                      ),
                      const Spacer(),
                      if (fromGps)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.gps_fixed_rounded,
                                  size: 13,
                                  color: AppColors.primaryGreen),
                              SizedBox(width: 4),
                              Text('Vị trí GPS',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGreen)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nhãn địa chỉ
                  TextFormField(
                    controller: labelCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nhãn (VD: Nhà, Công ty, Kho rác)',
                      prefixIcon: const Icon(
                          Icons.label_outline_rounded,
                          color: AppColors.primaryGreen),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Địa chỉ đầy đủ
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Vui lòng nhập địa chỉ'
                            : null,
                    decoration: InputDecoration(
                      labelText: 'Địa chỉ đầy đủ *',
                      hintText:
                          'VD: 123 Lê Lợi, P.1, Q.1, TP.HCM',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Icon(Icons.location_on_outlined,
                            color: AppColors.primaryGreen),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                  ),

                  // Tọa độ GPS (chỉ hiện khi có GPS)
                  if (fromGps) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryGreen.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location_rounded,
                              size: 14, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Text(
                            'Tọa độ: ${lat.toStringAsFixed(5)}°N, ${lng.toStringAsFixed(5)}°E',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4A5D50)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Đặt mặc định
                  InkWell(
                    onTap: () =>
                        setSheet(() => isDefault = !isDefault),
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: isDefault,
                          onChanged: (v) =>
                              setSheet(() => isDefault = v ?? false),
                          activeColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        const Text(
                          'Đặt làm địa chỉ mặc định',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A2E22)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nút lưu
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) {
                                return;
                              }
                              setSheet(() => isSaving = true);
                              try {
                                await _repo.addAddress(
                                  widget.token,
                                  fullAddress:
                                      addressCtrl.text.trim(),
                                  label: labelCtrl.text.trim().isEmpty
                                      ? null
                                      : labelCtrl.text.trim(),
                                  lat: lat,
                                  lng: lng,
                                  isDefault: isDefault,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _loadAddresses();
                                if (mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                          _snack('Đã thêm địa chỉ mới!'));
                                }
                              } catch (e) {
                                setSheet(() => isSaving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    _snack(
                                      e
                                          .toString()
                                          .replaceAll('Exception: ', ''),
                                      isError: true,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text('Lưu địa chỉ',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  SnackBar _snack(String msg, {bool isError = false}) => SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      );

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF1A2E22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Địa chỉ đã lưu',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A2E22)),
        ),
        centerTitle: true,
        actions: [
          // GPS icon
          IconButton(
            icon: const Icon(Icons.gps_fixed_rounded,
                color: AppColors.primaryGreen, size: 22),
            tooltip: 'Dùng vị trí hiện tại',
            onPressed: _addFromGps,
          ),
          // Thêm thủ công
          IconButton(
            icon: const Icon(Icons.add_rounded,
                color: AppColors.primaryGreen, size: 26),
            tooltip: 'Nhập địa chỉ thủ công',
            onPressed: () => _showAddSheet(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryGreen))
          : _error != null
              ? _buildError()
              : _addresses.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
      floatingActionButton:
          (!_isLoading && _error == null && _addresses.isNotEmpty)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // GPS FAB
                    FloatingActionButton(
                      heroTag: 'fab_gps',
                      onPressed: _addFromGps,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      tooltip: 'Vị trí hiện tại',
                      child: const Icon(Icons.gps_fixed_rounded,
                          color: AppColors.primaryGreen),
                    ),
                    const SizedBox(height: 12),
                    // Manual FAB
                    FloatingActionButton.extended(
                      heroTag: 'fab_manual',
                      onPressed: () => _showAddSheet(),
                      backgroundColor: AppColors.primaryGreen,
                      icon: const Icon(Icons.add_rounded,
                          color: Colors.white),
                      label: const Text('Thêm địa chỉ',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                )
              : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.orange),
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A8B80))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadAddresses,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4EB),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.location_off_outlined,
                  size: 48, color: AppColors.primaryGreen),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có địa chỉ nào',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E22)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn có thể thêm nhiều địa chỉ — nhà, công ty, nơi để rác...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF7A8B80)),
            ),
            const SizedBox(height: 28),
            // GPS
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addFromGps,
                icon: const Icon(Icons.gps_fixed_rounded,
                    color: Colors.white),
                label: const Text('Dùng vị trí hiện tại',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Thủ công
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddSheet(),
                icon: const Icon(Icons.edit_location_alt_outlined,
                    color: AppColors.primaryGreen),
                label: const Text('Nhập địa chỉ thủ công',
                    style: TextStyle(
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side:
                      const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _loadAddresses,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: _addresses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildAddressCard(_addresses[i]),
      ),
    );
  }

  Widget _buildAddressCard(UserAddressModel addr) {
    // Phân biệt GPS (tọa độ thực) vs tọa độ mặc định (10.7769, 106.7009)
    final hasRealGps = addr.latitude != null &&
        addr.longitude != null &&
        !(addr.latitude! > 10.776 &&
            addr.latitude! < 10.778 &&
            addr.longitude! > 106.700 &&
            addr.longitude! < 106.702);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: addr.isDefault
            ? Border.all(color: AppColors.primaryGreen, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: addr.isDefault
                    ? AppColors.primaryGreen.withValues(alpha: 0.12)
                    : const Color(0xFFF3F7F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                hasRealGps
                    ? Icons.gps_fixed_rounded
                    : Icons.location_on_rounded,
                color: addr.isDefault
                    ? AppColors.primaryGreen
                    : const Color(0xFF7A8B80),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row nhãn + badges
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (addr.addressLabel != null)
                        Text(
                          addr.addressLabel!,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A2E22)),
                        ),
                      if (addr.isDefault)
                        _badge('Mặc định',
                            AppColors.primaryGreen, Icons.star_rounded),
                      if (hasRealGps)
                        _badge('GPS', Colors.blue,
                            Icons.gps_fixed_rounded),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addr.fullAddress,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4A5D50),
                        height: 1.4),
                  ),
                  if (hasRealGps) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${addr.latitude!.toStringAsFixed(5)}°N, ${addr.longitude!.toStringAsFixed(5)}°E',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFB0BEC5)),
                    ),
                  ],
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: Color(0xFFB0BEC5), size: 22),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == 'default') _setDefault(addr.addressId);
                if (val == 'delete') _deleteAddress(addr.addressId);
              },
              itemBuilder: (_) => [
                if (!addr.isDefault)
                  const PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded,
                            color: AppColors.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text('Đặt làm mặc định'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      SizedBox(width: 8),
                      Text('Xóa địa chỉ',
                          style: TextStyle(color: Colors.redAccent)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
