import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/suasanpham.dart';
import '../logic/xoasanpham.dart';

// =============================================================================
// TRANG HIỂN THỊ DANH SÁCH SẢN PHẨM
// =============================================================================
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const Color primaryRed = Color(0xFF7A0C16);
  static const Color textColor = Color(0xFF333333);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // MỞ BOTTOM SHEET SỬA
  // ---------------------------------------------------------------------------
  void _openEditSheet(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProductSheet(docId: docId, data: data),
    );
  }

  // ---------------------------------------------------------------------------
  // GỌI DỊCH VỤ XÓA
  // ---------------------------------------------------------------------------
  Future<void> _onDeleteOne(String docId, String tenSanPham) async {
    await DeleteProductService.deleteOne(
      context: context,
      docId: docId,
      tenSanPham: tenSanPham,
    );
  }

  Future<void> _onDeleteAll() async {
    await DeleteProductService.deleteAll(context: context);
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );
  }

  // Thanh tìm kiếm + nút xóa tất cả
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchField = _buildSearchField();
          final deleteButton = _buildDeleteAllButton();

          if (constraints.maxWidth < 600) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: deleteButton),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              deleteButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        onChanged: (value) =>
            setState(() => _searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Tìm theo mã hoặc tên sản phẩm',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  tooltip: 'Xóa nội dung tìm kiếm',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryRed),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }

  Widget _buildDeleteAllButton() {
    return ElevatedButton.icon(
      onPressed: _onDeleteAll,
      icon: const Icon(Icons.delete_sweep_outlined, size: 18),
      label: const Text(
        'Xóa tất cả',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.red.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sanpham')
          .orderBy('ngay_tao', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryRed),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
        }

        final allDocs = snapshot.data?.docs ?? [];

        // Lọc theo tìm kiếm
        final docs = _searchQuery.isEmpty
            ? allDocs
            : allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final ma = (data['ma_san_pham'] ?? '').toString().toLowerCase();
                final ten = (data['ten_san_pham'] ?? '')
                    .toString()
                    .toLowerCase();
                return ma.contains(_searchQuery) || ten.contains(_searchQuery);
              }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'Chưa có sản phẩm nào'
                      : 'Không tìm thấy sản phẩm nào',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 18,
                    color: primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Danh sách sản phẩm',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${docs.length} sản phẩm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 720) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildMobileProductCard(doc.id, data, index);
                      },
                    );
                  }

                  return _buildWideTable(docs, constraints);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideTable(
    List<QueryDocumentSnapshot> docs,
    BoxConstraints constraints,
  ) {
    const minTableWidth = 1080.0;
    final tableWidth = constraints.maxWidth < minTableWidth
        ? minTableWidth
        : constraints.maxWidth;

    return Container(
      color: const Color(0xFFF5F5F5),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: tableWidth,
          height: constraints.maxHeight,
          child: Column(
            children: [
              _buildTableHeader(),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Expanded(
                child: ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildProductRow(doc.id, data, index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileProductCard(
    String docId,
    Map<String, dynamic> data,
    int index,
  ) {
    final name = _displayValue(data['ten_san_pham'], fallback: 'Chưa có tên');
    final code = _displayValue(data['ma_san_pham']);
    final type = _displayValue(data['loai_cuon']);
    final image = data['hinh_anh_base64'];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFEAECEF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(image, docId, data, size: 68),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          code,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (type != '—') ...[
                        const SizedBox(height: 4),
                        Text(
                          type,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Column(
                  children: [
                    _smallActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Sửa sản phẩm',
                      color: Colors.blue,
                      onTap: () => _openEditSheet(docId, data),
                    ),
                    const SizedBox(height: 6),
                    _smallActionButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Xóa sản phẩm',
                      color: Colors.red,
                      onTap: () => _onDeleteOne(docId, name),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _buildSpecChip(
                  'Độ dày',
                  '${_displayValue(data['do_day_mm'])} mm',
                  Icons.straighten,
                ),
                _buildSpecChip(
                  'Khổ rộng',
                  '${_displayValue(data['chieu_rong_mm'])} mm',
                  Icons.swap_horiz,
                ),
                _buildSpecChip(
                  'Giá bán',
                  _formatPrice(data['gia_ban']),
                  Icons.sell_outlined,
                  emphasize: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Sản phẩm ${index + 1}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecChip(
    String label,
    String value,
    IconData icon, {
    bool emphasize = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: emphasize ? const Color(0xFFFFF7ED) : const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: emphasize ? const Color(0xFFFED7AA) : const Color(0xFFE9ECEF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: emphasize ? const Color(0xFFB45309) : Colors.grey.shade600,
          ),
          const SizedBox(width: 5),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: emphasize ? const Color(0xFF9A3412) : textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _displayValue(dynamic value, {String fallback = '—'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _headerCell('STT', flex: 1),
          _headerCell('Hình ảnh', flex: 2),
          _headerCell('Mã SP', flex: 2),
          _headerCell('Tên sản phẩm', flex: 4),
          _headerCell('Loại cuộn', flex: 3),
          _headerCell('Độ dày (mm)', flex: 2),
          _headerCell('Chiều rộng (mm)', flex: 2),
          _headerCell('Giá bán (VNĐ)', flex: 2),
          _headerCell('Hành động', flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF888888),
        ),
      ),
    );
  }

  Widget _buildProductRow(String docId, Map<String, dynamic> data, int index) {
    final tenSanPham = _displayValue(
      data['ten_san_pham'],
      fallback: 'Sản phẩm này',
    );

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // STT
          Expanded(
            flex: 1,
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 13, color: textColor),
            ),
          ),
          // Hình ảnh nhỏ
          Expanded(
            flex: 2,
            child: _buildThumbnail(data['hinh_anh_base64'], docId, data),
          ),
          // Mã SP
          Expanded(
            flex: 2,
            child: Text(
              _displayValue(data['ma_san_pham']),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primaryRed,
              ),
            ),
          ),
          // Tên SP
          Expanded(
            flex: 4,
            child: Text(
              tenSanPham,
              style: const TextStyle(fontSize: 13, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Loại cuộn
          Expanded(
            flex: 3,
            child: Text(
              _displayValue(data['loai_cuon']),
              style: const TextStyle(fontSize: 12, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Độ dày
          Expanded(
            flex: 2,
            child: Text(
              _displayValue(data['do_day_mm']),
              style: const TextStyle(fontSize: 13, color: textColor),
            ),
          ),
          // Chiều rộng
          Expanded(
            flex: 2,
            child: Text(
              _displayValue(data['chieu_rong_mm']),
              style: const TextStyle(fontSize: 13, color: textColor),
            ),
          ),
          // Giá bán
          Expanded(
            flex: 2,
            child: Text(
              _formatPrice(data['gia_ban']),
              style: const TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // Hành động
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Nút Sửa
                Tooltip(
                  message: 'Sửa sản phẩm',
                  child: InkWell(
                    onTap: () => _openEditSheet(docId, data),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút Xóa
                Tooltip(
                  message: 'Xóa sản phẩm',
                  child: InkWell(
                    onTap: () => _onDeleteOne(docId, tenSanPham),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Icon(
                        Icons.delete_outline,
                        size: 15,
                        color: Colors.red.shade700,
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
  // DECODE BASE64 AN TOÀN
  // ---------------------------------------------------------------------------
  /// Hỗ trợ Base64 thường, data URI, Base64 URL-safe và bytes Firestore.
  Uint8List? _decodeBase64(dynamic imageData) {
    if (imageData is Uint8List) return imageData;
    if (imageData is List) {
      try {
        return Uint8List.fromList(imageData.cast<int>());
      } catch (_) {
        return null;
      }
    }

    var encoded = imageData?.toString().trim() ?? '';
    if (encoded.isEmpty) return null;
    if (encoded.toLowerCase().startsWith('data:')) {
      final commaIndex = encoded.indexOf(',');
      if (commaIndex < 0) return null;
      encoded = encoded.substring(commaIndex + 1);
    }

    encoded = encoded
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('-', '+')
        .replaceAll('_', '/');
    if (encoded.isEmpty || encoded.length % 4 == 1) return null;
    final padding = encoded.length % 4;
    if (padding != 0) encoded += '=' * (4 - padding);

    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ẢNH NHỎ – nhấn để xem phóng to
  // ---------------------------------------------------------------------------
  Widget _buildThumbnail(
    dynamic imageData,
    String docId,
    Map<String, dynamic> data, {
    double size = 48,
  }) {
    final bytes = _decodeBase64(imageData);

    if (bytes == null) {
      return Tooltip(
        message: 'Nhấn Sửa để thêm ảnh',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            size: size * 0.4,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return Tooltip(
      message: 'Nhấn để phóng to',
      child: GestureDetector(
        onTap: () => _showImageDialog(bytes),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: size,
            height: size,
            color: const Color(0xFFF7F8FA),
            child: Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Icon(
                  Icons.broken_image_outlined,
                  size: size * 0.4,
                  color: Colors.red.shade300,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog phóng to ảnh
  void _showImageDialog(Uint8List bytes) {
    final screenSize = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          width: screenSize.width < 600 ? screenSize.width - 48 : 520,
          height: screenSize.height * 0.7,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: SizedBox.expand(
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Đóng ảnh',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '—';
    final num val = price is num ? price : num.tryParse(price.toString()) ?? 0;
    if (val == 0) return '—';
    final parts = val.toStringAsFixed(0).split('');
    final result = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) result.write('.');
      result.write(parts[i]);
    }
    return '${result}đ';
  }
}
