import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/repositories/yard_repository.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class YardEditProfileScreen extends StatefulWidget {
  final String token;
  final bool isInitialSetup;
  const YardEditProfileScreen({super.key, required this.token, this.isInitialSetup = false});

  @override
  State<YardEditProfileScreen> createState() => _YardEditProfileScreenState();
}

class _YardEditProfileScreenState extends State<YardEditProfileScreen> {
  final _yardRepo = YardRepository();
  bool _isLoading = true;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await _yardRepo.getProfile(token: widget.token);
      if (mounted) {
        setState(() {
          _nameCtrl.text = profile['scrapYardName'] ?? '';
          _addressCtrl.text = profile['address'] ?? '';
          _hoursCtrl.text = profile['operatingHours'] ?? '';
          _latitude = (profile['latitude'] as num?)?.toDouble();
          _longitude = (profile['longitude'] as num?)?.toDouble();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoading = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Vui lòng bật GPS trên thiết bị!');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Cần cấp quyền vị trí để lấy tọa độ.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Quyền vị trí bị từ chối vĩnh viễn.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${position.latitude}&lon=${position.longitude}&format=json&accept-language=vi',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'GreenCycleApp/1.0 (contact@greencycle.vn)',
        'Accept-Language': 'vi',
      });
      
      String addr = '';
      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        addr = (json['display_name'] as String?) ?? '';
      }

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (addr.isNotEmpty) {
            _addressCtrl.text = addr;
          }
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Đã lấy vị trí thành công!'),
          backgroundColor: Color(0xFF1B8E5A),
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập tên vựa và địa chỉ!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhấn nút Lấy Vị Trí GPS!'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _yardRepo.updateProfile(
        token: widget.token,
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        operatingHours: _hoursCtrl.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cập nhật hồ sơ vựa thành công!'),
          backgroundColor: Color(0xFF1B8E5A),
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
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
      onPopInvoked: (didPop) {
        if (widget.isInitialSetup) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn phải cập nhật vị trí để tiếp tục!'), backgroundColor: Colors.orange),
          );
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
                              child: Text('Đây là lần đầu đăng nhập. Vui lòng lấy vị trí GPS và cập nhật thông tin!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    _buildTextField('Tên vựa', 'Nhập tên vựa...', _nameCtrl, Icons.storefront_rounded),
                    const SizedBox(height: 20),
                    _buildTextField('Địa chỉ', 'Nhập địa chỉ...', _addressCtrl, Icons.location_on_rounded, maxLines: 2),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.gps_fixed_rounded, size: 20, color: Color(0xFF1B8E5A)),
                        label: const Text('Lấy vị trí GPS hiện tại', style: TextStyle(color: Color(0xFF1B8E5A), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1B8E5A)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _getLocation,
                      ),
                    ),
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tọa độ: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildTextField('Giờ hoạt động', 'VD: 08:00 - 18:00', _hoursCtrl, Icons.access_time_rounded),
                    const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
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
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0BEC5)),
            prefixIcon: Icon(icon, color: const Color(0xFF7A8B80), size: 22),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
