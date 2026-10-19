import 'package:flutter/material.dart';
import '../../../../core/utils/location_helper.dart';
import '../../data/repositories/yard_repository.dart';

class YardEditProfileScreen extends StatefulWidget {
  final String token;
  final bool isInitialSetup;

  const YardEditProfileScreen({
    super.key,
    required this.token,
    this.isInitialSetup = false,
  });

  @override
  State<YardEditProfileScreen> createState() => _YardEditProfileScreenState();
}

class _YardEditProfileScreenState extends State<YardEditProfileScreen> {
  final _yardRepo = YardRepository();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocating = false;
  bool _isSearchingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _yardRepo.getProfile(token: widget.token);
      if (mounted) {
        setState(() {
          _nameCtrl.text = p['name']?.toString() ?? '';
          _addressCtrl.text = p['address']?.toString() ?? '';
          _hoursCtrl.text = p['operatingHours']?.toString() ?? '';
          _latitude = (p['latitude'] as num?)?.toDouble();
          _longitude = (p['longitude'] as num?)?.toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  // ─── Lấy vị trí GPS của thiết bị ───────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position == null) {
        throw Exception('Không thể xác định vị trí GPS. Hãy kiểm tra cài đặt vị trí.');
      }

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Thử dịch ngược sang tên địa chỉ (không bắt buộc, không để lỗi này làm mất tọa độ)
      final addr = await LocationHelper.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (addr != null && addr.isNotEmpty && _addressCtrl.text.trim().isEmpty) {
        _addressCtrl.text = addr;
      }

      if (mounted) {
        setState(() => _isLocating = false);
        _showSnack('Đã lấy vị trí GPS thành công!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLocating = false);
        final msg = e.toString().replaceAll('Exception: ', '');
        _showLocationError(msg);
      }
    }
  }

  // ─── Tìm tọa độ từ địa chỉ đã nhập tay ─────────────────────────────────
  Future<void> _searchCoordinatesFromAddress() async {
    final text = _addressCtrl.text.trim();
    if (text.isEmpty) {
      _showSnack('Vui lòng nhập địa chỉ trước khi tìm tọa độ', isError: true);
      return;
    }

    setState(() => _isSearchingAddress = true);
    try {
      final result = await LocationHelper.getCoordinatesFromAddress(text);
      if (result != null) {
        setState(() {
          _latitude = result.latitude;
          _longitude = result.longitude;
          _isSearchingAddress = false;
        });
        _showSnack(
          'Đã tìm thấy tọa độ theo địa chỉ thành công!',
          isError: false,
        );
      } else {
        setState(() => _isSearchingAddress = false);
        _showSnack(
          'Không tìm thấy tọa độ cho địa chỉ này. Hãy nhập chi tiết hơn (gồm Phường/Xã, Quận/Huyện, Tỉnh/TP) hoặc nhấn "Lấy GPS hiện tại".',
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isSearchingAddress = false);
      _showSnack('Lỗi tìm kiếm tọa độ: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  // ─── Lưu hồ sơ vựa ───────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (name.isEmpty || address.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ tên vựa và địa chỉ!', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    // Nếu chưa có tọa độ, tự động thử geocoding từ địa chỉ đã nhập
    if (_latitude == null || _longitude == null) {
      try {
        final result = await LocationHelper.getCoordinatesFromAddress(address);
        if (result != null) {
          _latitude = result.latitude;
          _longitude = result.longitude;
        }
      } catch (_) {}
    }

    // Nếu vẫn chưa có tọa độ sau khi thử
    if (_latitude == null || _longitude == null) {
      setState(() => _isSaving = false);
      _showSnack(
        'Chưa có tọa độ GPS cho vựa. Vui lòng bấm "Lấy vị trí GPS" hoặc "Tìm tọa độ từ địa chỉ"!',
        isError: true,
      );
      return;
    }

    try {
      await _yardRepo.updateProfile(
        token: widget.token,
        name: name,
        address: address,
        operatingHours: _hoursCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Cập nhật hồ sơ vựa thành công!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1B8E5A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showLocationError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: 'Cài đặt',
        textColor: Colors.white,
        onPressed: () {
          if (msg.contains('Cài đặt')) {
            LocationHelper.openAppSettings();
          } else {
            LocationHelper.openLocationSettings();
          }
        },
      ),
    ));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isInitialSetup,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.isInitialSetup) {
          _showSnack('Bạn phải cập nhật thông tin và vị trí vựa để tiếp tục!', isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F7F4),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF1A2E22)),
          automaticallyImplyLeading: !widget.isInitialSetup,
          title: const Text(
            'Hồ sơ vựa',
            style: TextStyle(color: Color(0xFF1A2E22), fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8E5A)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.isInitialSetup)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đây là lần đầu đăng nhập. Vui lòng xác định vị trí GPS và cập nhật thông tin!',
                                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                      ),

                    _buildTextField('Tên vựa', 'Nhập tên vựa...', _nameCtrl, Icons.storefront_rounded),
                    const SizedBox(height: 20),

                    // Ô nhập địa chỉ
                    _buildTextField(
                      'Địa chỉ vựa',
                      'Nhập số nhà, tên đường, phường/xã, quận/huyện...',
                      _addressCtrl,
                      Icons.location_on_rounded,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    // 2 Nút chọn tọa độ: GPS hiện tại hoặc Tìm theo địa chỉ
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isLocating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B8E5A)),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 18, color: Color(0xFF1B8E5A)),
                            label: Text(
                              _isLocating ? 'Đang lấy GPS...' : 'Lấy GPS máy',
                              style: const TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1B8E5A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: (_isLocating || _isSearchingAddress) ? null : _getLocation,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isSearchingAddress
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B8E5A)),
                                  )
                                : const Icon(Icons.search_rounded, size: 18, color: Color(0xFF1B8E5A)),
                            label: Text(
                              _isSearchingAddress ? 'Đang tìm...' : 'Tìm tọa độ từ địa chỉ',
                              style: const TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1B8E5A)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: (_isLocating || _isSearchingAddress) ? null : _searchCoordinatesFromAddress,
                          ),
                        ),
                      ],
                    ),

                    // Trạng thái tọa độ
                    const SizedBox(height: 10),
                    if (_latitude != null && _longitude != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF1B8E5A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Đã có tọa độ: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF1B8E5A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text(
                          'Chưa xác định tọa độ. Hãy bấm "Lấy GPS máy" hoặc "Tìm tọa độ từ địa chỉ".',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 20),
                    _buildTextField('Giờ hoạt động', 'VD: 07:00 - 19:00', _hoursCtrl, Icons.access_time_rounded),
                    const SizedBox(height: 36),

                    // Nút Lưu
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _isLocating || _isSearchingAddress) ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8E5A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Lưu thay đổi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E22)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF1B8E5A)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1B8E5A), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
