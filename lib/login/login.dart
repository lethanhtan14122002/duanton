import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isRegister = true;

  // Controllers
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController(text: 'Nam');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  // Quản lý trạng thái
  String? _generatedOtp;
  bool _isOtpSent = false;
  bool _isOtpVerified = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  final _formKey = GlobalKey<FormState>();

  // =========================================================================
  // ⚠️ ĐIỀN CHÍNH XÁC 3 THÔNG TIN TỪ EMAILJS CỦA BẠN VÀO ĐÂY:
  // =========================================================================
  final String _emailJsServiceId = 'service_760t9lm'; // Ví dụ: service_xxxxxx
  final String _emailJsTemplateId =
      'template_25uik27'; // Kiểm tra lại kĩ ID của Contact Us
  final String _emailJsPublicKey =
      'WCEBhdYMnmw5ErSL7'; // Ví dụ: user_xxxxxx / public_key

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // 1. HÀM TẠO VÀ GỬI MÃ OTP
  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Email hợp lệ trước khi lấy OTP'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Sinh mã OTP 6 chữ số ngẫu nhiên
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();
    print("🔥 MÃ OTP VỪA TẠO LÀ: $_generatedOtp");

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost', // Giúp tránh lỗi CORS nếu chạy trên Web
        },
        body: jsonEncode({
          'service_id': _emailJsServiceId,
          'template_id': _emailJsTemplateId,
          'user_id': _emailJsPublicKey,
          'template_params': {
            'to_email': email, // Khớp với {{to_email}} trên Template EmailJS
            'otp_code':
                _generatedOtp, // Khớp với {{otp_code}} trên Template EmailJS
          },
        }),
      );

      print("👉 Server EmailJS Response Code: ${response.statusCode}");
      print("👉 Server EmailJS Response Body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _isOtpSent = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã gửi mã OTP đến $email! (Kiểm tra cả thư mục Spam)',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('EmailJS Báo Lỗi: ${response.body}');
      }
    } catch (e) {
      print("❌ LỖI GỬI OTP: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi OTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. HÀM XÁC THỰC MÃ OTP
  void _verifyOtp() {
    FocusScope.of(context).unfocus(); // Ẩn bàn phím
    if (_otpController.text.trim() == _generatedOtp) {
      setState(() {
        _isOtpVerified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xác nhận mã OTP thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP không đúng! Vui lòng kiểm tra lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 3. HÀM ĐĂNG KÝ / ĐĂNG NHẬP
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (isRegister) {
      if (!_isOtpVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bấm Xác Nhận mã OTP trước!')),
        );
        return;
      }

      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng đồng ý với Điều khoản & Chính sách'),
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mật khẩu xác nhận không trùng khớp')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      if (isRegister) {
        // Đăng ký Firebase Auth
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        // Lưu thông tin vào Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'fullName': _fullNameController.text.trim(),
              'dob': _dobController.text.trim(),
              'gender': _genderController.text.trim(),
              'email': _emailController.text.trim(),
              'isEmailVerified': true,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tạo tài khoản thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Đăng nhập
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Đã xảy ra lỗi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              children: [
                // TAB SWITCHER
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRegister = false),
                        child: _buildTabHeader('Đăng nhập', !isRegister),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isRegister = true),
                        child: _buildTabHeader('Đăng ký', isRegister),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // KHUNG BẢNG NHẬP
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isRegister) ...[
                          _buildSectionTitle('Thông tin tài khoản'),
                          const SizedBox(height: 12),
                          _buildLabel('Họ và tên', isRequired: true),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _fullNameController,
                            validator: (val) =>
                                val!.isEmpty ? 'Vui lòng nhập họ tên' : null,
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Ngày sinh'),
                                    const SizedBox(height: 6),
                                    _buildTextField(
                                      controller: _dobController,
                                      hintText: 'DD/MM/YYYY',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Giới tính'),
                                    const SizedBox(height: 6),
                                    _buildTextField(
                                      controller: _genderController,
                                      hintText: 'Nam',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        _buildSectionTitle('Thông tin đăng nhập'),
                        const SizedBox(height: 12),

                        _buildLabel('Email', isRequired: isRegister),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) =>
                                    val!.isEmpty ? 'Vui lòng nhập Email' : null,
                              ),
                            ),
                            if (isRegister) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: Text(
                                    _isOtpSent ? 'Gửi lại' : 'Lấy OTP',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),

                        // KHU VỰC Ô NHẬP OTP (HIỆN KHI BẤM LẤY OTP)
                        if (isRegister && _isOtpSent) ...[
                          _buildLabel('Mã OTP từ Gmail', isRequired: true),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _otpController,
                                  hintText: '6 chữ số',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: _isOtpVerified ? null : _verifyOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isOtpVerified
                                        ? Colors.green
                                        : Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: Text(
                                    _isOtpVerified ? 'Đã xác thực' : 'Xác nhận',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        _buildLabel('Mật khẩu', isRequired: true),
                        const SizedBox(height: 6),
                        _buildTextField(
                          controller: _passwordController,
                          isObscure: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            if (val.length < 6) {
                              return 'Mật khẩu phải từ 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        if (isRegister) ...[
                          _buildLabel('Xác nhận mật khẩu', isRequired: true),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            isObscure: true,
                            validator: (val) => val!.isEmpty
                                ? 'Vui lòng xác nhận mật khẩu'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (val) {
                                    setState(
                                      () => _agreeToTerms = val ?? false,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Tôi đã đọc và đồng ý với các ',
                                      ),
                                      TextSpan(
                                        text: 'Điều khoản sử dụng',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      TextSpan(text: ' và '),
                                      TextSpan(
                                        text:
                                            'Chính sách bảo mật thông tin cá nhân',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // NÚT ĐĂNG KÝ / ĐĂNG NHẬP
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A25E1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    isRegister ? 'ĐĂNG KÝ' : 'ĐĂNG NHẬP',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET PHỤ GIAO DIỆN ---
  Widget _buildTabHeader(String title, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? Colors.redAccent : Colors.grey.shade300,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: '* ',
              style: TextStyle(color: Colors.red),
            ),
          TextSpan(text: label),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    String? hintText,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        fillColor: const Color(0xFFF5F5F5),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
