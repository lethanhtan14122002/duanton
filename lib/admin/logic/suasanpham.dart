import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// =============================================================================
// BOTTOM SHEET SỬA SẢN PHẨM
// Yêu cầu pubspec.yaml:
//   dependencies:
//     image_picker: ^1.1.2
//
// Android — android/app/src/main/AndroidManifest.xml, thêm trong <manifest>:
//   <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
//
// iOS — ios/Runner/Info.plist, thêm:
//   <key>NSPhotoLibraryUsageDescription</key>
//   <string>Ứng dụng cần truy cập ảnh để chọn ảnh sản phẩm.</string>
// =============================================================================
class EditProductSheet extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const EditProductSheet({super.key, required this.docId, required this.data});

  @override
  State<EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<EditProductSheet> {
  static const Color primaryRed = Color(0xFF7A0C16);
  static const Color textColor = Color(0xFF333333);

  final _formKey = GlobalKey<FormState>();
  bool _autoValidate = false;
  bool _isLoading = false;
  bool _isPickingImage = false;

  // Ảnh sản phẩm – lưu dưới dạng bytes để hiển thị & lưu Base64
  Uint8List? _imageBytes;

  // Controllers
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _thicknessController;
  late TextEditingController _widthController;
  late TextEditingController _lengthController;
  late TextEditingController _weightController;
  late TextEditingController _priceController;
  late TextEditingController _vatController;
  late TextEditingController _supplierController;
  late TextEditingController _originController;
  late TextEditingController _notesController;

  // Dropdown values
  String? selectedCoilType;
  String? selectedSheetType;
  String? selectedColor;
  String? selectedUnit;
  String? selectedSurface;
  String? selectedStandard;

  // ---------------------------------------------------------------------------
  // Danh sách lựa chọn
  // ---------------------------------------------------------------------------
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

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _codeController = TextEditingController(text: d['ma_san_pham'] ?? '');
    _nameController = TextEditingController(text: d['ten_san_pham'] ?? '');
    _thicknessController = TextEditingController(
      text: _numToStr(d['do_day_mm']),
    );
    _widthController = TextEditingController(
      text: _numToStr(d['chieu_rong_mm']),
    );
    _lengthController = TextEditingController(
      text: _numToStr(d['chieu_dai_m']),
    );
    _weightController = TextEditingController(
      text: _numToStr(d['trong_luong_kgm']),
    );
    _priceController = TextEditingController(text: _numToStr(d['gia_ban']));
    _vatController = TextEditingController(text: _numToStr(d['vat']));
    _supplierController = TextEditingController(text: d['nha_cung_cap'] ?? '');
    _originController = TextEditingController(text: d['xuat_xu'] ?? '');
    _notesController = TextEditingController(text: d['ghi_chu'] ?? '');

    // Giải mã Base64 thành bytes nếu đã có ảnh
    final base64Str = d['hinh_anh_base64']?.toString() ?? '';
    if (base64Str.isNotEmpty) {
      try {
        _imageBytes = base64Decode(base64Str);
      } catch (_) {
        _imageBytes = null;
      }
    }

    selectedCoilType = _pick(coilTypes, d['loai_cuon']);
    selectedSheetType = _pick(sheetTypes, d['loai_ton']);
    selectedColor = _pick(productColors, d['mau_sac']);
    selectedUnit = _pick(units, d['don_vi']);
    selectedSurface = _pick(surfaceTypes, d['be_mat']);
    selectedStandard = _pick(standards, d['tieu_chuan']);
  }

  String _numToStr(dynamic v) {
    if (v == null || v == 0 || v == 0.0) return '';
    return v.toString();
  }

  String? _pick(List<String> list, dynamic value) {
    if (value == null) return null;
    return list.contains(value.toString()) ? value.toString() : null;
  }

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
  // CHỌN ẢNH TỪ THƯ VIỆN
  // ---------------------------------------------------------------------------
  Future<void> _pickImageFromGallery() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // nén nhẹ để giảm dung lượng Base64
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) return; // người dùng hủy

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() => _imageBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Không thể chọn ảnh: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  // ---------------------------------------------------------------------------
  // LƯU THAY ĐỔI LÊN FIRESTORE
  // ---------------------------------------------------------------------------
  Future<void> _saveChanges() async {
    setState(() => _autoValidate = true);

    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Vui lòng nhập đầy đủ thông tin bắt buộc (*)'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Encode ảnh sang Base64 (hoặc giữ nguyên chuỗi cũ nếu không đổi)
      final base64Str = _imageBytes != null ? base64Encode(_imageBytes!) : '';

      await FirebaseFirestore.instance
          .collection('sanpham')
          .doc(widget.docId)
          .update({
            'ma_san_pham': _codeController.text.trim(),
            'ten_san_pham': _nameController.text.trim(),
            'loai_cuon': selectedCoilType,
            'loai_ton': selectedSheetType,
            'mau_sac': selectedColor,
            'do_day_mm':
                double.tryParse(_thicknessController.text.trim()) ?? 0.0,
            'chieu_rong_mm':
                double.tryParse(_widthController.text.trim()) ?? 0.0,
            'chieu_dai_m':
                double.tryParse(_lengthController.text.trim()) ?? 0.0,
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
            'hinh_anh_base64': base64Str,
            'ngay_cap_nhat': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Cập nhật sản phẩm thành công!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi cập nhật: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle kéo
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: primaryRed,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sửa sản phẩm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Mã: ${widget.data['ma_san_pham'] ?? ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Nội dung form
          Expanded(
            child: Stack(
              children: [
                Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate
                      ? AutovalidateMode.always
                      : AutovalidateMode.disabled,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldGrid(),
                        const SizedBox(height: 20),

                        // -------------------------------------------------------
                        // PHẦN HÌNH ẢNH
                        // -------------------------------------------------------
                        _buildLabel('Hình ảnh sản phẩm'),
                        const SizedBox(height: 8),
                        _buildImagePicker(),
                        const SizedBox(height: 16),

                        _buildLabel('Ghi chú'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          maxLength: 500,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'chi tiết sản phẩm',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: primaryRed),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                // Loading overlay
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.2),
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryRed),
                    ),
                  ),
              ],
            ),
          ),

          // Nút hành động
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              14,
              24,
              MediaQuery.of(context).viewInsets.bottom + 14,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: Colors.black87, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(
                      Icons.save_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET CHỌN ẢNH TỪ THƯ VIỆN
  // Nhấn vào ảnh (hoặc placeholder) → mở thư viện ảnh
  // ---------------------------------------------------------------------------
  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImageFromGallery,
      child: Stack(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _imageBytes != null
                    ? Colors.grey.shade200
                    : primaryRed.withOpacity(0.3),
                width: _imageBytes != null ? 1 : 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _isPickingImage
                // Đang tải ảnh
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryRed,
                    ),
                  )
                : _imageBytes != null
                // Đã có ảnh — hiển thị ảnh
                ? Image.memory(
                    _imageBytes!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _placeholderWidget(
                      icon: Icons.broken_image_outlined,
                      label: 'Ảnh lỗi. Nhấn để chọn lại',
                      iconColor: Colors.red.shade300,
                    ),
                  )
                // Chưa có ảnh — placeholder
                : _placeholderWidget(
                    icon: Icons.add_photo_alternate_outlined,
                    label: 'Nhấn để chọn ảnh từ thư viện',
                    iconColor: primaryRed.withOpacity(0.5),
                  ),
          ),

          // Badge "Đổi ảnh" ở góc dưới phải khi đã có ảnh
          if (_imageBytes != null && !_isPickingImage)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Đổi ảnh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Nút xóa ảnh ở góc trên phải
          if (_imageBytes != null && !_isPickingImage)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: () => setState(() => _imageBytes = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholderWidget({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 40, color: iconColor),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // LƯỚI TRƯỜNG NHẬP LIỆU (2 cột trên màn lớn, 1 cột trên nhỏ)
  // ---------------------------------------------------------------------------
  Widget _buildFieldGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth > 700 ? 2 : 1;
        const sp = 16.0;

        final fields = [
          _editTextField(
            'Mã sản phẩm *',
            _codeController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
          ),
          _editTextField(
            'Tên sản phẩm *',
            _nameController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
          ),
          _editDropdown(
            'Loại cuộn *',
            'Chọn loại cuộn',
            selectedCoilType,
            coilTypes,
            (v) => setState(() => selectedCoilType = v),
            validator: (v) => v == null ? 'Vui lòng chọn' : null,
          ),
          _editDropdown(
            'Loại Tôn *',
            'Chọn loại tôn',
            selectedSheetType,
            sheetTypes,
            (v) => setState(() => selectedSheetType = v),
            validator: (v) => v == null ? 'Vui lòng chọn' : null,
          ),
          _editDropdown(
            'Màu sắc *',
            'Chọn màu sắc',
            selectedColor,
            productColors,
            (v) => setState(() => selectedColor = v),
            validator: (v) => v == null ? 'Vui lòng chọn' : null,
          ),
          _editTextField(
            'Độ dày (mm) *',
            _thicknessController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Không được để trống';
              if (double.tryParse(v.trim()) == null) return 'Nhập số hợp lệ';
              return null;
            },
          ),
          _editTextField(
            'Chiều rộng (mm) *',
            _widthController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Không được để trống';
              if (double.tryParse(v.trim()) == null) return 'Nhập số hợp lệ';
              return null;
            },
          ),
          _editTextField(
            'Chiều dài (m) *',
            _lengthController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Không được để trống';
              if (double.tryParse(v.trim()) == null) return 'Nhập số hợp lệ';
              return null;
            },
          ),
          _editDropdown(
            'Đơn vị *',
            'Chọn đơn vị',
            selectedUnit,
            units,
            (v) => setState(() => selectedUnit = v),
            validator: (v) => v == null ? 'Vui lòng chọn' : null,
          ),
          _editTextField(
            'Trọng lượng (kg/m) *',
            _weightController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Không được để trống';
              if (double.tryParse(v.trim()) == null) return 'Nhập số hợp lệ';
              return null;
            },
          ),
          _editTextField(
            'Giá Bán (VNĐ) *',
            _priceController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Không được để trống';
              if (double.tryParse(v.trim()) == null) return 'Nhập số hợp lệ';
              return null;
            },
          ),
          _editTextField(
            'VAT (%) *',
            _vatController,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Không được để trống';
              final val = double.tryParse(v.trim());
              if (val == null) return 'Nhập số hợp lệ';
              if (val < 0 || val > 100) return 'VAT phải từ 0–100';
              return null;
            },
          ),
          _editTextField(
            'Nhà Cung Cấp *',
            _supplierController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
          ),
          _editTextField(
            'Xuất Xứ *',
            _originController,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
          ),
          _editDropdown(
            'Bề mặt *',
            'Chọn bề mặt',
            selectedSurface,
            surfaceTypes,
            (v) => setState(() => selectedSurface = v),
            validator: (v) => v == null ? 'Vui lòng chọn' : null,
          ),
          _editDropdown(
            'Tiêu chuẩn *',
            'Chọn tiêu chuẩn',
            selectedStandard,
            standards,
            (v) => setState(() => selectedStandard = v),
            validator: (v) => v == null ? 'Vui lòng chọn' : null,
          ),
        ];

        if (cols == 1) {
          return Column(
            children: fields
                .map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: sp),
                    child: f,
                  ),
                )
                .toList(),
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < fields.length; i += 2) {
          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fields[i]),
                const SizedBox(width: sp),
                Expanded(
                  child: i + 1 < fields.length
                      ? fields[i + 1]
                      : const SizedBox(),
                ),
              ],
            ),
          );
          if (i + 2 < fields.length) rows.add(const SizedBox(height: sp));
        }
        return Column(children: rows);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // WIDGET HELPERS
  // ---------------------------------------------------------------------------
  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _editTextField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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

  Widget _editDropdown(
    String label,
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          autovalidateMode: _autoValidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(fontSize: 13, color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
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
}
