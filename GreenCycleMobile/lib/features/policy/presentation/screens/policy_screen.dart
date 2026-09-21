import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Màn hình Điều khoản & Chính sách bảo mật.
class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const _terms = [
    _PolicySection(
      icon: Icons.assignment_outlined,
      title: '1. Điều khoản sử dụng dịch vụ',
      content:
          'Bằng cách sử dụng ứng dụng GreenCycle, bạn đồng ý tuân thủ các điều khoản này. '
          'GreenCycle cung cấp nền tảng kết nối người bán rác tái chế với người thu gom và vựa phế liệu. '
          'Người dùng phải từ đủ 16 tuổi trở lên để sử dụng dịch vụ.',
    ),
    _PolicySection(
      icon: Icons.account_circle_outlined,
      title: '2. Tài khoản người dùng',
      content:
          'Bạn có trách nhiệm bảo mật thông tin tài khoản của mình. '
          'Không được chia sẻ mật khẩu hoặc cho phép người khác sử dụng tài khoản của bạn. '
          'GreenCycle không chịu trách nhiệm về các thiệt hại phát sinh từ việc tài khoản bị đánh cắp do sơ suất của người dùng.',
    ),
    _PolicySection(
      icon: Icons.eco_outlined,
      title: '3. GreenPoints và giao dịch',
      content:
          'GreenPoints (GP) là điểm thưởng nội bộ, không có giá trị tiền tệ thực và không thể quy đổi ra tiền mặt. '
          'GreenCycle có quyền điều chỉnh tỷ lệ đổi điểm và danh sách quà tặng mà không cần thông báo trước. '
          'Mọi giao dịch GP đều được ghi lại và có thể xem trong lịch sử.',
    ),
    _PolicySection(
      icon: Icons.gavel_outlined,
      title: '4. Hành vi bị cấm',
      content:
          'Nghiêm cấm sử dụng ứng dụng cho mục đích bất hợp pháp, gian lận hoặc gây hại cho người dùng khác. '
          'Không được cố tình khai báo sai khối lượng hoặc loại rác tái chế. '
          'Vi phạm sẽ dẫn đến khóa tài khoản vĩnh viễn và có thể bị xử lý theo pháp luật.',
    ),
    _PolicySection(
      icon: Icons.update_outlined,
      title: '5. Thay đổi điều khoản',
      content:
          'GreenCycle có thể cập nhật điều khoản sử dụng theo thời gian. '
          'Người dùng sẽ được thông báo về những thay đổi quan trọng qua email hoặc thông báo trong ứng dụng. '
          'Tiếp tục sử dụng dịch vụ sau khi cập nhật đồng nghĩa với việc bạn chấp nhận điều khoản mới.',
    ),
  ];

  static const _privacy = [
    _PolicySection(
      icon: Icons.person_search_outlined,
      title: '1. Thông tin chúng tôi thu thập',
      content:
          'Chúng tôi thu thập: Thông tin định danh (họ tên, số điện thoại, email), '
          'Dữ liệu vị trí GPS (khi bạn cho phép, chỉ dùng để tìm vựa gần và xác nhận đơn hàng), '
          'Lịch sử giao dịch và hành vi sử dụng ứng dụng, '
          'Thông tin thiết bị (loại máy, phiên bản hệ điều hành).',
    ),
    _PolicySection(
      icon: Icons.lock_outline,
      title: '2. Cách chúng tôi bảo vệ dữ liệu',
      content:
          'Dữ liệu được mã hóa khi truyền tải (HTTPS/TLS). '
          'Mật khẩu được băm bằng thuật toán bcrypt. '
          'Chúng tôi không bán hoặc chia sẻ thông tin cá nhân với bên thứ ba vì mục đích thương mại.',
    ),
    _PolicySection(
      icon: Icons.share_outlined,
      title: '3. Chia sẻ dữ liệu',
      content:
          'Thông tin của bạn chỉ được chia sẻ với: '
          'Người thu gom / chủ vựa (thông tin liên quan đến đơn hàng), '
          'Đối tác cung cấp dịch vụ bản đồ (Google Maps), '
          'Cơ quan nhà nước khi có yêu cầu pháp lý.',
    ),
    _PolicySection(
      icon: Icons.location_on_outlined,
      title: '4. Dữ liệu vị trí',
      content:
          'GPS chỉ được sử dụng khi bạn đang dùng các tính năng yêu cầu định vị (tìm vựa gần, thêm địa chỉ). '
          'Chúng tôi không theo dõi vị trí của bạn ở chế độ nền. '
          'Bạn có thể thu hồi quyền GPS bất kỳ lúc nào trong Cài đặt thiết bị.',
    ),
    _PolicySection(
      icon: Icons.delete_forever_outlined,
      title: '5. Quyền của người dùng',
      content:
          'Bạn có quyền: Xem, sửa hoặc xóa thông tin cá nhân bất kỳ lúc nào. '
          'Yêu cầu xóa tài khoản và toàn bộ dữ liệu liên quan. '
          'Từ chối cho phép ứng dụng thu thập dữ liệu vị trí. '
          'Để thực hiện các quyền này, liên hệ: support@greencycle.vn.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1A2E22)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Điều khoản & Chính sách',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A2E22)),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: const Color(0xFF7A8B80),
          indicatorColor: AppColors.primaryGreen,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Điều khoản sử dụng'),
            Tab(text: 'Chính sách bảo mật'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPolicyList(_terms, 'Cập nhật lần cuối: 01/09/2026'),
          _buildPolicyList(_privacy, 'Cập nhật lần cuối: 01/09/2026'),
        ],
      ),
    );
  }

  Widget _buildPolicyList(List<_PolicySection> sections, String lastUpdated) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length + 2, // header + sections + footer
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              lastUpdated,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8B80)),
            ),
          );
        }
        if (index == sections.length + 1) {
          return const Padding(
            padding: EdgeInsets.only(top: 12, bottom: 32),
            child: Text(
              'Nếu bạn có câu hỏi về các điều khoản hoặc chính sách này, '
              'vui lòng liên hệ: support@greencycle.vn',
              style: TextStyle(fontSize: 13, color: Color(0xFF7A8B80), height: 1.5),
              textAlign: TextAlign.center,
            ),
          );
        }

        final section = sections[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, color: AppColors.primaryGreen, size: 18),
              ),
              title: Text(
                section.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2E22),
                ),
              ),
              iconColor: AppColors.primaryGreen,
              collapsedIconColor: const Color(0xFFB0BEC5),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(
                  section.content,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF4A5D50),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PolicySection {
  final IconData icon;
  final String title;
  final String content;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.content,
  });
}
