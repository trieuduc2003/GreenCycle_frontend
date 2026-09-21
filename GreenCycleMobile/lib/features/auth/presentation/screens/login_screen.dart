import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/login_dto.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_login_button.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';
import '../../../seller/presentation/screens/seller_home_screen.dart';
import '../../../yard/presentation/screens/yard_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  // Google OAuth Client IDs
  static const String _serverClientId =
      '348318262413-l1g4gv3ij3op2uev9end4rusujti2fvb.apps.googleusercontent.com';
  static const String _clientId =
      '348318262413-vep193tl9593jihtf1bbmjsl175asnna.apps.googleusercontent.com';

  @override
  void initState() {
    super.initState();
    _ensureGoogleSignInInitialized();
  }

  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
        clientId: _clientId,
      ).timeout(const Duration(seconds: 5));
      _isGoogleSignInInitialized = true;
    } catch (_) {
      // Bỏ qua lỗi nếu đã init từ trước trên platform khác
      _isGoogleSignInInitialized = true;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ Số điện thoại và Mật khẩu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = LoginRequestDto(phone: phone, password: password);
      final response = await _authRepository.login(request);

      setState(() => _isLoading = false);

      if (!mounted) return;
      _navigateBasedOnRole(response);
    } catch (e) {
      setState(() => _isLoading = false);
      _showMessage(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _onGoogleLoginPressed() async {
    setState(() => _isGoogleLoading = true);

    try {
      await _ensureGoogleSignInInitialized();
      final account = await GoogleSignIn.instance.authenticate().timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Đăng nhập Google quá hạn. Hãy kiểm tra kết nối mạng của bạn.'),
      );
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không nhận được mã xác thực từ Google. Vui lòng thử lại.');
      }

      final response = await _authRepository.googleLogin(idToken);

      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      _navigateBasedOnRole(response);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGoogleLoading = false);

      final errorMsg = e.toString().replaceAll('Exception: ', '');
      // Không hiển thị lỗi nếu người dùng chủ động đóng/hủy popup đăng nhập Google
      if (!errorMsg.toLowerCase().contains('canceled') &&
          !errorMsg.toLowerCase().contains('cancelled') &&
          !errorMsg.toLowerCase().contains('hủy')) {
        _showMessage(errorMsg);
      }
    }
  }

  void _navigateBasedOnRole(LoginResponseDto response) {
    Widget destination;
    switch (response.roleName) {
      case 'Seller':
        destination = SellerHomeScreen(token: response.token, fullName: response.fullName);
        break;
      case 'ScrapYard':
      case 'YardOwner':
        destination = YardDashboardScreen(token: response.token, fullName: response.fullName);
        break;
      case 'Collector':
      default:
        destination = RoleSelectionScreen(token: response.token, fullName: response.fullName);
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              _buildHeaderIcon(),
              const SizedBox(height: 28),
              const Text('Chào mừng bạn', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('Đăng nhập để bắt đầu tái chế.', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              AuthTextField(
                label: 'Số điện thoại',
                hintText: '090 123 4567',
                prefixIcon: Icons.phone_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'Mật khẩu',
                hintText: '••••••••',
                prefixIcon: Icons.lock_outline,
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 28),

              _buildSubmitButton(),
              const SizedBox(height: 24),
              _buildDivider(),
              const SizedBox(height: 24),

              GoogleLoginButton(
                onPressed: (_isLoading || _isGoogleLoading) ? null : _onGoogleLoginPressed,
                isLoading: _isGoogleLoading,
              ),
              const SizedBox(height: 40),
              _buildFooterTerms(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(16)),
      child: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 32),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (_isLoading || _isGoogleLoading) ? null : _onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Đăng nhập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.dividerColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('hoặc', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(child: Divider(color: AppColors.dividerColor)),
      ],
    );
  }

  Widget _buildFooterTerms() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            text: 'Chưa có tài khoản? ',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            children: [
              TextSpan(
                text: 'Đăng ký ngay',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}