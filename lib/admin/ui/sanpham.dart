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
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  // Thanh tìm kiếm + nút xóa tất cả
  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Ô tìm kiếm
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo mã hoặc tên sản phẩm...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Colors.grey,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: primaryRed),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nút xóa tất cả
          ElevatedButton.icon(
            onPressed: _onDeleteAll,
            icon: const Icon(
              Icons.delete_sweep_outlined,
              size: 16,
              color: Colors.white,
            ),
            label: const Text(
              'Xóa tất cả',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
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
            // Thống kê
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Tổng: ${docs.length} sản phẩm',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
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
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
    final hinhAnh = data['hinh_anh_base64']?.toString() ?? '';

    return Container(
      color: index.isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
          Expanded(flex: 2, child: _buildThumbnail(hinhAnh, docId, data)),
          // Mã SP
          Expanded(
            flex: 2,
            child: Text(
              data['ma_san_pham'] ?? '—',
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
              data['ten_san_pham'] ?? '—',
              style: const TextStyle(fontSize: 13, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Loại cuộn
          Expanded(
            flex: 3,
            child: Text(
              data['loai_cuon'] ?? '—',
              style: const TextStyle(fontSize: 12, color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Độ dày
          Expanded(
            flex: 2,
            child: Text(
              '${data['do_day_mm'] ?? '—'}',
              style: const TextStyle(fontSize: 13, color: textColor),
            ),
          ),
          // Chiều rộng
          Expanded(
            flex: 2,
            child: Text(
              '${data['chieu_rong_mm'] ?? '—'}',
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
                    onTap: () =>
                        _onDeleteOne(docId, data['ten_san_pham'] ?? 'này'),
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
  /// Trả về null nếu chuỗi rỗng hoặc không phải base64 hợp lệ.
  Uint8List? _decodeBase64(String base64Str) {
    final s = base64Str.trim();
    if (s.isEmpty) return null;
    try {
      return base64Decode(s);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // ẢNH NHỎ – nhấn để xem phóng to
  // ---------------------------------------------------------------------------
  Widget _buildThumbnail(
    String base64Str,
    String docId,
    Map<String, dynamic> data,
  ) {
    final bytes = _decodeBase64(base64Str);

    if (bytes == null) {
      return Tooltip(
        message: 'Nhấn Sửa để thêm ảnh',
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 20,
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
          borderRadius: BorderRadius.circular(6),
          child: Image.memory(
            bytes,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: Colors.red.shade300,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Dialog phóng to ảnh
  void _showImageDialog(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InteractiveViewer(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(32),
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
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
