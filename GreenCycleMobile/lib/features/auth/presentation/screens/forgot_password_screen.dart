import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _authRepository = AuthRepository();

  // Controllers
  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // UI States
  int _currentStep = 0; // 0: Nhập email, 1: Nhập OTP & Mật khẩu mới
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Countdown cho Step 1 (gửi lại OTP)
  int _countdown = 300;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 300);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String get _countdownText {
    final m = _countdown ~/ 60;
    final s = _countdown % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _enteredOtp => _otpControllers.map((c) => c.text).join();

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showSnack(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppColors.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─── Step 1: Gửi mã OTP qua Email ──────────────────────────────────────
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Vui lòng nhập địa chỉ email của bạn');
      return;
    }
    if (!_isValidEmail(email)) {
      _showSnack('Email không đúng định dạng');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.forgotPasswordSendOtp(email);
      _startCountdown();
      setState(() {
        _isLoading = false;
        _currentStep = 1;
      });
      _showSnack('Mã OTP đã được gửi về email của bạn!', isError: false);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Step 2: Gửi lại mã OTP ────────────────────────────────────────────
  Future<void> _handleResendOtp() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    try {
      await _authRepository.forgotPasswordSendOtp(email);
      _startCountdown();
      for (final c in _otpControllers) {
        c.clear();
      }
      _otpFocusNodes[0].requestFocus();
      _showSnack('Đã gửi lại mã OTP vào email của bạn!', isError: false);
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ─── Step 2: Xác nhận OTP & Đổi mật khẩu mới ───────────────────────────
  Future<void> _handleResetPassword() async {
    final otp = _enteredOtp;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (otp.length < 6) {
      _showSnack('Vui lòng nhập đủ 6 chữ số mã OTP');
      return;
    }
    if (newPass.length < 6) {
      _showSnack('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (newPass != confirmPass) {
      _showSnack('Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authRepository.resetPassword(
        email: _emailController.text.trim(),
        otpCode: otp,
        newPassword: newPass,
      );

      setState(() => _isLoading = false);
      if (!mounted) return;

      _showSnack('Đổi mật khẩu thành công! Vui lòng đăng nhập lại.', isError: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () {
            if (_currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: _currentStep == 0 ? _buildStepEmail() : _buildStepResetPassword(),
        ),
      ),
    );
  }

  // ─── Widget: Bước 1 Nhập Email ──────────────────────────────────────────
  Widget _buildStepEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primaryGreen, size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'Quên mật khẩu?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhập địa chỉ email đăng ký tài khoản của bạn để nhận mã OTP khôi phục mật khẩu.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: 'vidu@gmail.com',
            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryGreen),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSendOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Gửi mã xác thực OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── Widget: Bước 2 Nhập OTP và Mật khẩu mới ────────────────────────────
  Widget _buildStepResetPassword() {
    final isExpired = _countdown <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.primaryGreen, size: 30),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đặt lại mật khẩu',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            children: [
              const TextSpan(text: 'Mã OTP đã được gửi tới email:\n'),
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Mã xác thực (6 số)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildOtpBox(index)),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isExpired ? 'Mã OTP đã hết hạn. ' : 'Mã hết hạn sau $_countdownText. ',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            GestureDetector(
              onTap: (isExpired && !_isLoading) ? _handleResendOtp : null,
              child: Text(
                'Gửi lại',
                style: TextStyle(
                  color: isExpired ? AppColors.primaryGreen : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                  decoration: isExpired ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _newPasswordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryGreen),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu mới',
            prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primaryGreen),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Đổi mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final isFilled = _otpControllers[index].text.isNotEmpty;

    return SizedBox(
      width: 48,
      height: 58,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: isFilled ? AppColors.cardBackground : Colors.white,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isFilled ? AppColors.primaryGreen : AppColors.inputBorder,
              width: isFilled ? 2 : 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2.5),
          ),
        ),
        onChanged: (v) {
          if (v.length == 1 && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (v.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
