import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// SECTION: SẢN PHẨM ƯU ĐÃI
// - Load từ Firestore collection 'sanpham'
// - Sắp xếp VAT cao → thấp
// - Carousel 3 thẻ/trang, nút < >
// - Hover ảnh: hiện giỏ hàng + overlay "chi tiết sản phẩm"
// =============================================================================
class SanPhamUuDaiSection extends StatefulWidget {
  /// Callback khi nhấn "chi tiết sản phẩm"
  final void Function(Map<String, dynamic> data)? onViewDetail;

  /// Callback khi nhấn giỏ hàng
  final void Function(Map<String, dynamic> data)? onAddToCart;

  const SanPhamUuDaiSection({super.key, this.onViewDetail, this.onAddToCart});

  @override
  State<SanPhamUuDaiSection> createState() => _SanPhamUuDaiSectionState();
}

class _SanPhamUuDaiSectionState extends State<SanPhamUuDaiSection> {
  static const Color _blue = Color(0xFF1565C0);
  static const Color _lightBlue = Color(0xFF1E88E5);

  // Số thẻ hiển thị cùng lúc
  static const int _perPage = 3;

  int _page = 0; // trang hiện tại (mỗi trang = _perPage thẻ)

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sanpham')
          .orderBy('vat', descending: true) // VAT cao → thấp
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(child: Text('Lỗi: ${snapshot.error}')),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'Chưa có sản phẩm nào',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        final totalPages = (docs.length / _perPage).ceil();
        // Đảm bảo _page không vượt quá giới hạn sau khi reload
        final safePage = _page.clamp(0, totalPages - 1);

        // Lấy slice thẻ của trang hiện tại
        final start = safePage * _perPage;
        final end = (start + _perPage).clamp(0, docs.length);
        final pageDocs = docs.sublist(start, end);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              // Tiêu đề
              const Text(
                'Sản phẩm ưu đãi',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _blue,
                  letterSpacing: 0.5,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 24),

              // Carousel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Nút trái
                    _NavButton(
                      icon: Icons.chevron_left,
                      enabled: safePage > 0,
                      onTap: () => setState(() => _page = safePage - 1),
                    ),
                    const SizedBox(width: 8),

                    // Danh sách thẻ
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth =
                              (constraints.maxWidth - (_perPage - 1) * 16) /
                              _perPage;
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(pageDocs.length, (i) {
                              final data =
                                  pageDocs[i].data() as Map<String, dynamic>;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: i < pageDocs.length - 1 ? 16 : 0,
                                ),
                                child: SizedBox(
                                  width: cardWidth,
                                  child: _ProductCard(
                                    data: data,
                                    onViewDetail: widget.onViewDetail != null
                                        ? () => widget.onViewDetail!(data)
                                        : null,
                                    onAddToCart: widget.onAddToCart != null
                                        ? () => widget.onAddToCart!(data)
                                        : null,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),
                    // Nút phải
                    _NavButton(
                      icon: Icons.chevron_right,
                      enabled: safePage < totalPages - 1,
                      onTap: () => setState(() => _page = safePage + 1),
                    ),
                  ],
                ),
              ),

              // Chỉ số trang (dots)
              if (totalPages > 1) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == safePage ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == safePage
                            ? _lightBlue
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// =============================================================================
// NÚT ĐIỀU HƯỚNG < >
// =============================================================================
class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade100 : Colors.grey.shade50,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled ? Colors.grey.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }
}

// =============================================================================
// THẺ SẢN PHẨM
// =============================================================================
class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onViewDetail;
  final VoidCallback? onAddToCart;

  const _ProductCard({required this.data, this.onViewDetail, this.onAddToCart});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hovering = false;

  static const Color _blue = Color(0xFF1565C0);
  static const Color _overlayBlue = Color(0xFF1E88E5);

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final vat = (data['vat'] as num?)?.toDouble() ?? 0;
    final giaBan = (data['gia_ban'] as num?)?.toDouble() ?? 0;
    // Giá gốc = giá bán * (1 + VAT/100)
    final giaGoc = giaBan > 0 && vat > 0 ? giaBan * (1 + vat / 100) : 0.0;
    final tenSanPham = data['ten_san_pham'] ?? '—';
    final loaiTon = data['loai_ton'] ?? data['loai_cuon'] ?? '—';
    final base64Str = data['hinh_anh_base64']?.toString() ?? '';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onViewDetail, // mobile: tap = xem chi tiết
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _hovering ? _blue : Colors.grey.shade300,
              width: _hovering ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------------------------
              // PHẦN ẢNH + OVERLAY
              // ---------------------------------------------------------------
              Stack(
                children: [
                  // Ảnh sản phẩm
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      child: _buildImage(base64Str),
                    ),
                  ),

                  // Badge giảm giá (VAT%)
                  if (vat > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${vat.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),

                  // Icon giỏ hàng – hiện khi hover
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _hovering ? 1 : 0,
                    child: // Giỏ hàng – luôn hiện, nằm ngay phía trên thanh chi tiết
                    Positioned(
                      bottom: 0,
                      child: GestureDetector(
                        onTap: widget.onAddToCart,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shopping_cart,
                            size: 22,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Overlay "chi tiết sản phẩm" – hiện khi hover
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _hovering ? 1 : 0,
                      child: GestureDetector(
                        onTap: widget.onViewDetail,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _overlayBlue.withOpacity(0.88),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'chi tiết sản phẩm',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ---------------------------------------------------------------
              // PHẦN THÔNG TIN
              // ---------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loại tôn
                    Text(
                      loaiTon,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Tên sản phẩm
                    Text(
                      tenSanPham,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF222222),
                        height: 1.35,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Giá
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Giá gốc (gạch ngang)
                        if (giaGoc > 0) ...[
                          Text(
                            _formatPrice(giaGoc),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        // Giá bán
                        Text(
                          _formatPrice(giaBan),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    // VAT label
                    const SizedBox(height: 4),
                    Text(
                      'VAT: ${vat.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hiển thị ảnh từ Base64 hoặc placeholder
  Widget _buildImage(String base64Str) {
    if (base64Str.isEmpty) {
      return Container(
        color: const Color(0xFFF0F4F8),
        child: Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }

    Uint8List? bytes;
    try {
      bytes = base64Decode(base64Str.trim());
    } catch (_) {
      bytes = null;
    }

    if (bytes == null) {
      return Container(
        color: const Color(0xFFF0F4F8),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.red.shade200,
          ),
        ),
      );
    }

    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFF0F4F8),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 40,
            color: Colors.red.shade200,
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price <= 0) return '—';
    final s = price.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }
}
