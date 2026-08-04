import 'dart:convert'; // base64Encode
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const Color primaryRed = Color(0xFF7A0C16);
  static const Color textColor = Color(0xFF333333);

  // Firestore giới hạn 1MB/document — ảnh base64 tăng ~33% so với bản gốc
  // => giới hạn ảnh gốc tối đa 700KB để base64 an toàn dưới 1MB
  static const int _maxImageBytes = 700 * 1024; // 700 KB

  final _formKey = GlobalKey<FormState>();
  String? _codeDuplicateError;
  bool _autoValidate = false;
  bool _isLoading = false;

  Uint8List? _selectedImageBytes;
  String? _selectedImageName; // lưu tên file để hiển thị

  final List<String> sheetTypes = [
    'Tôn lạnh (GL)',
    'Tôn mạ kẽm (GI)',
    'Tôn mạ màu (PPGI)',
    'Tôn lạnh mạ màu (PPGL)',
    'Tôn cán sóng',
    'Tôn phẳng',
    'Tôn cách nhiệt PU',
    'Tôn cách nhiệt EPS',
    'Tôn cách nhiệt Rockwool',
    'Tôn Seamlock',
    'Tôn Cliplock',
    'Tôn giả ngói',
  ];
  final List<String> coilTypes = [
    'HRC - Cuộn thép cán nóng',
    'CRC - Cuộn thép cán nguội',
    'GI - Cuộn thép mạ kẽm',
    'GL - Cuộn thép mạ hợp kim nhôm kẽm',
    'PPGI - Cuộn thép mạ màu',
    'PPGL - Cuộn thép mạ màu nhôm kẽm',
  ];
  final List<String> productColors = [
    'RAL 3003 - Đỏ Ruby',
    'RAL 3009 - Đỏ Oxide',
    'RAL 5015 - Xanh da trời',
    'RAL 5002 - Xanh dương',
    'RAL 6005 - Xanh rêu',
    'RAL 6029 - Xanh lá',
    'RAL 7004 - Xám ghi',
    'RAL 7035 - Xám nhạt',
    'RAL 7016 - Xám than',
    'RAL 8017 - Nâu socola',
    'RAL 9002 - Trắng sữa',
    'RAL 9010 - Trắng tinh',
    'RAL 9006 - Bạc',
    'RAL 9005 - Đen',
  ];
  final List<String> units = [
    'Kg',
    'Tấn',
    'Mét (m)',
    'Milimét (mm)',
    'Cuộn',
    'Tấm',
    'Kiện',
    'Cây',
  ];
  final List<String> surfaceTypes = [
    'Bóng (Glossy)',
    'Mờ (Matt)',
    'Nhám (Textured)',
    'Vân gỗ (Wood Grain)',
    'Vân đá (Stone Pattern)',
    'Mạ kẽm (Spangle)',
    'Mạ kẽm không bông (Zero Spangle)',
  ];
  final List<String> standards = [
    'ASTM A653 - Thép mạ kẽm (GI)',
    'ASTM A792 - Thép mạ hợp kim nhôm kẽm (GL)',
    'ASTM A755 - Tôn mạ màu',
    'JIS G3302 - Thép mạ kẽm',
    'JIS G3321 - Thép mạ hợp kim nhôm kẽm',
    'JIS G3312 - Thép mạ màu',
    'EN 10346 - Thép mạ (Châu Âu)',
    'TCVN',
  ];

  // Controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _thicknessController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Dropdown values
  String? selectedCoilType;
  String? selectedSheetType;
  String? selectedColor;
  String? selectedUnit;
  String? selectedSurface;
  String? selectedStandard;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _thicknessController.dispose();
    _widthController.dispose();
    _lengthController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _vatController.dispose();
    _supplierController.dispose();
    _originController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // CHỌN ẢNH — kiểm tra kích thước trước khi chấp nhận
  // ---------------------------------------------------------------------------
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200, // resize xuống tối đa 1200px
        imageQuality: 80, // nén 80% để giảm dung lượng
      );
      if (image == null) return;

      final Uint8List bytes = await image.readAsBytes();

      // Kiểm tra dung lượng sau khi nén
      if (bytes.length > _maxImageBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ảnh quá lớn (${_formatBytes(bytes.length)}). '
                    'Vui lòng chọn ảnh nhỏ hơn ${_formatBytes(_maxImageBytes)}.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = image.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // CHUYỂN BYTES → BASE64 STRING
  // ---------------------------------------------------------------------------
  String? _encodeImageToBase64() {
    if (_selectedImageBytes == null) return null;
    return base64Encode(_selectedImageBytes!);
  }

  // ---------------------------------------------------------------------------
  // KIỂM TRA TRÙNG MÃ SẢN PHẨM
  // ---------------------------------------------------------------------------
  Future<bool> _isProductCodeDuplicate(String code) async {
    final query = await FirebaseFirestore.instance
        .collection('sanpham')
        .where('ma_san_pham', isEqualTo: code)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // LƯU SẢN PHẨM (bao gồm ảnh base64)
  // ---------------------------------------------------------------------------
  Future<void> _saveProductToFirebase({bool isDraft = false}) async {
    setState(() {
      _autoValidate = true;
      _codeDuplicateError = null;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      _showWarningSnackBar(
        'Vui lòng nhập đầy đủ tất cả các thông tin bắt buộc (*)',
      );
      return;
    }

    setState(() => _isLoading = true);

    // Kiểm tra trùng mã
    final code = _codeController.text.trim();
    final isDuplicate = await _isProductCodeDuplicate(code);
    if (isDuplicate) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _codeDuplicateError =
            'Mã sản phẩm "$code" đã tồn tại. Vui lòng dùng mã khác.';
      });
      _formKey.currentState?.validate();
      return;
    }

    // Encode ảnh sang base64 (null nếu không có ảnh)
    final String? imageBase64 = _encodeImageToBase64();

    try {
      await FirebaseFirestore.instance.collection('sanpham').add({
        'ma_san_pham': _codeController.text.trim(),
        'ten_san_pham': _nameController.text.trim(),
        'loai_cuon': selectedCoilType,
        'loai_ton': selectedSheetType,
        'mau_sac': selectedColor,
        'do_day_mm': double.tryParse(_thicknessController.text.trim()) ?? 0.0,
        'chieu_rong_mm': double.tryParse(_widthController.text.trim()) ?? 0.0,
        'chieu_dai_m': double.tryParse(_lengthController.text.trim()) ?? 0.0,
        'don_vi': selectedUnit,
        'trong_luong_kgm':
            double.tryParse(_weightController.text.trim()) ?? 0.0,
        'gia_ban': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'vat': double.tryParse(_vatController.text.trim()) ?? 0.0,
        'nha_cung_cap': _supplierController.text.trim(),
        'xuat_xu': _originController.text.trim(),
        'be_mat': selectedSurface,
        'tieu_chuan': selectedStandard,
        'ghi_chu': _notesController.text.trim(),
        // ---- TRƯỜNG ẢNH BASE64 ----
        'hinh_anh_base64': imageBase64, // null nếu không chọn ảnh
        'co_hinh_anh': imageBase64 != null,
        // ----------------------------
        'trang_thai': isDraft ? 'nhap' : 'da_them',
        'ngay_tao': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                isDraft
                    ? 'Đã lưu nháp thành công!'
                    : 'Thêm sản phẩm thành công!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      _resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Lỗi khi lưu sản phẩm: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _codeController.clear();
    _nameController.clear();
    _thicknessController.clear();
    _widthController.clear();
    _lengthController.clear();
    _weightController.clear();
    _priceController.clear();
    _vatController.clear();
    _supplierController.clear();
    _originController.clear();
    _notesController.clear();
    setState(() {
      selectedCoilType = null;
      selectedSheetType = null;
      selectedColor = null;
      selectedUnit = null;
      selectedSurface = null;
      selectedStandard = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _autoValidate = false;
      _codeDuplicateError = null;
    });
  }

  // ---------------------------------------------------------------------------
  // HELPER: định dạng bytes → KB/MB
  // ---------------------------------------------------------------------------
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: _autoValidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('1. SẢN PHẨM'),
                        const SizedBox(height: 16),
                        _buildProductInfoForm(),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFEEEEEE), height: 1),
                        const SizedBox(height: 24),
                        _buildSectionTitle('2. HÌNH ẢNH SẢN PHẨM'),
                        const SizedBox(height: 16),
                        _buildImageUploadSection(),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFEEEEEE), height: 1),
                        const SizedBox(height: 24),
                        _buildSectionTitle('3. GHI CHÚ'),
                        const SizedBox(height: 16),
                        _buildNotesSection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: primaryRed),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: primaryRed,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORM NHẬP LIỆU
  // ---------------------------------------------------------------------------
  Widget _buildProductInfoForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = constraints.maxWidth > 900
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);
        const double sp = 16.0;

        return Column(
          children: [
            _buildResponsiveRow(
              [
                _buildTextField(
                  'Mã sản phẩm',
                  hintText: 'VD: HS-001',
                  controller: _codeController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Mã sản phẩm không được để trống';
                    if (_codeDuplicateError != null) return _codeDuplicateError;
                    return null;
                  },
                ),
                _buildTextField(
                  'Tên sản phẩm',
                  hintText: 'Nhập tên sản phẩm',
                  controller: _nameController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Tên sản phẩm không được để trống'
                      : null,
                ),
                _buildDropdown(
                  'Loại cuộn',
                  'Chọn loại cuộn',
                  selectedCoilType,
                  coilTypes,
                  (v) => setState(() => selectedCoilType = v),
                ),
                _buildDropdown(
                  'Loại Tôn',
                  'Chọn loại tôn',
                  selectedSheetType,
                  sheetTypes,
                  (v) => setState(() => selectedSheetType = v),
                ),
              ],
              cols,
              sp,
            ),
            const SizedBox(height: sp),

            _buildResponsiveRow(
              [
                _buildDropdown(
                  'Màu sắc',
                  'Chọn màu sắc',
                  selectedColor,
                  productColors,
                  (v) => setState(() => selectedColor = v),
                ),
                _buildTextField(
                  'Độ dày (mm)',
                  hintText: 'Nhập độ dày',
                  controller: _thicknessController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Độ dày không được để trống';
                    if (double.tryParse(v.trim()) == null)
                      return 'Nhập số hợp lệ';
                    return null;
                  },
                ),
                _buildTextField(
                  'Chiều rộng (mm)',
                  hintText: 'Nhập chiều rộng',
                  controller: _widthController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Chiều rộng không được để trống';
                    if (double.tryParse(v.trim()) == null)
                      return 'Nhập số hợp lệ';
                    return null;
                  },
                ),
                _buildTextField(
                  'Chiều dài (m)',
                  hintText: 'Nhập chiều dài',
                  controller: _lengthController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Chiều dài không được để trống';
                    if (double.tryParse(v.trim()) == null)
                      return 'Nhập số hợp lệ';
                    return null;
                  },
                ),
              ],
              cols,
              sp,
            ),
            const SizedBox(height: sp),

            _buildResponsiveRow(
              [
                _buildDropdown(
                  'Đơn vị',
                  'Chọn đơn vị',
                  selectedUnit,
                  units,
                  (v) => setState(() => selectedUnit = v),
                ),
                _buildTextField(
                  'Trọng lượng (kg/m)',
                  hintText: 'Nhập trọng lượng',
                  controller: _weightController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Trọng lượng không được để trống';
                    if (double.tryParse(v.trim()) == null)
                      return 'Nhập số hợp lệ';
                    return null;
                  },
                ),
                _buildTextField(
                  'Giá Bán (VNĐ)',
                  hintText: 'Nhập giá bán',
                  controller: _priceController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Giá bán không được để trống';
                    if (double.tryParse(v.trim()) == null)
                      return 'Nhập số hợp lệ';
                    return null;
                  },
                ),
                _buildTextField(
                  'VAT (%)',
                  hintText: 'VD: 8 hoặc 10',
                  controller: _vatController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'VAT không được để trống';
                    final val = double.tryParse(v.trim());
                    if (val == null) return 'Nhập số hợp lệ';
                    if (val < 0 || val > 100) return 'VAT phải từ 0–100';
                    return null;
                  },
                ),
              ],
              cols,
              sp,
            ),
            const SizedBox(height: sp),

            _buildResponsiveRow(
              [
                _buildTextField(
                  'Nhà Cung Cấp',
                  hintText: 'Nhập nhà cung cấp',
                  controller: _supplierController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nhà cung cấp không được để trống'
                      : null,
                ),
                _buildTextField(
                  'Xuất Xứ',
                  hintText: 'VD: Việt Nam, Nhật Bản',
                  controller: _originController,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Xuất xứ không được để trống'
                      : null,
                ),
                _buildDropdown(
                  'Bề mặt',
                  'Chọn bề mặt',
                  selectedSurface,
                  surfaceTypes,
                  (v) => setState(() => selectedSurface = v),
                ),
                _buildDropdown(
                  'Tiêu chuẩn',
                  'Chọn tiêu chuẩn',
                  selectedStandard,
                  standards,
                  (v) => setState(() => selectedStandard = v),
                ),
              ],
              cols,
              sp,
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveRow(
    List<Widget> children,
    int columns,
    double spacing,
  ) {
    if (columns == 1) {
      return Column(
        children: children
            .where((w) => w is! SizedBox)
            .map(
              (w) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: w,
              ),
            )
            .toList(),
      );
    }
    final List<Widget> row = [];
    for (int i = 0; i < children.length; i++) {
      row.add(Expanded(child: children[i]));
      if (i < children.length - 1) row.add(SizedBox(width: spacing));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: row);
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, {
    required String hintText,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: primaryRed),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String hintText,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        DropdownButtonFormField<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(fontSize: 13, color: textColor),
          autovalidateMode: _autoValidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          validator: (v) => v == null ? 'Vui lòng chọn $label' : null,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: primaryRed),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: Colors.red),
          ),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ẢNH SẢN PHẨM — hiển thị thông tin dung lượng + trạng thái base64
  // ---------------------------------------------------------------------------
  Widget _buildImageUploadSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 650;
        return Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cột trái: chọn ảnh
            Expanded(
              flex: isMobile ? 0 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _pickImage,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      height: 450,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 36,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Chọn ảnh lên',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          IgnorePointer(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: const Text(
                                'Chọn ảnh từ máy',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'JPG, PNG — tối đa ${_formatBytes(_maxImageBytes)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Thông tin ảnh đã chọn + trạng thái base64
                  if (_selectedImageBytes != null) ...[
                    const SizedBox(height: 8),
                    _buildImageInfoBadge(),
                  ],
                ],
              ),
            ),

            SizedBox(width: isMobile ? 0 : 20, height: isMobile ? 16 : 0),

            // Cột phải: preview ảnh
            Expanded(
              flex: isMobile ? 0 : 1,
              child: Container(
                height: 450,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedImageBytes == null
                    ? Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/t1.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _selectedImageBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Nút xóa ảnh
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Tooltip(
                              message: 'Xóa ảnh',
                              child: InkWell(
                                onTap: () => setState(() {
                                  _selectedImageBytes = null;
                                  _selectedImageName = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Badge hiển thị tên file, dung lượng gốc, kích thước base64 ước tính
  Widget _buildImageInfoBadge() {
    final int rawSize = _selectedImageBytes!.length;
    // Base64 tăng ~33% so với bản gốc
    final int b64Size = (rawSize * 4 / 3).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.green.shade700,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedImageName ?? 'Ảnh đã chọn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Dung lượng gốc: ${_formatBytes(rawSize)}  •  '
                  'Base64 lưu vào Firestore: ~${_formatBytes(b64Size)}',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // GHI CHÚ
  // ---------------------------------------------------------------------------
  Widget _buildNotesSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            maxLength: 500,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'chi tiết sản phẩm',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _notesController,
            builder: (_, value, __) => Text(
              '${value.text.length}/500',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NÚT HÀNH ĐỘNG
  // ---------------------------------------------------------------------------
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () => _saveProductToFirebase(isDraft: true),
            icon: const Icon(
              Icons.save_outlined,
              size: 16,
              color: Colors.black87,
            ),
            label: const Text(
              'Lưu nháp',
              style: TextStyle(color: Colors.black87, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _saveProductToFirebase(isDraft: false),
            icon: const Icon(Icons.check, size: 16, color: Colors.white),
            label: const Text(
              'Thêm sản phẩm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
