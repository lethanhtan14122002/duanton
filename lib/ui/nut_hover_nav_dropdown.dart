// ============================================================
//  HƯỚNG DẪN TÍCH HỢP
// ============================================================
//  1. Copy file này vào: lib/widgets/hover_nav_dropdown.dart
//
//  2. Import ở đầu file chứa buildDesktopHeader():
//       import 'package:your_app/widgets/hover_nav_dropdown.dart';
//
//  3. Thay Expanded của "SẢN PHẨM":
//       Expanded(
//         flex: 1,
//         child: HoverNavItem(
//           label: "SẢN PHẨM",
//           imageFuture: _imageFuture1,
//           dropdownType: DropdownType.products,
//           onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => day2())); },
//         ),
//       ),
//
//  4. Thay Expanded của "Thương hiệu":
//       Expanded(
//         flex: 1,
//         child: HoverNavItem(
//           label: "Thương hiệu",
//           imageFuture: _imageFuture1,
//           dropdownType: DropdownType.brands,
//           onTap: () { Navigator.push(context, MaterialPageRoute(builder: (_) => day2())); },
//         ),
//       ),
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

enum DropdownType { products, brands }

class HoverNavItem extends StatefulWidget {
  final String label;
  final Future<ui.Image> imageFuture;
  final DropdownType dropdownType;
  final VoidCallback onTap;

  const HoverNavItem({
    super.key,
    required this.label,
    required this.imageFuture,
    required this.dropdownType,
    required this.onTap,
  });

  @override
  State<HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<HoverNavItem> {
  OverlayEntry? _overlayEntry;
  final GlobalKey _key = GlobalKey();
  Timer? _hideTimer;

  // ★ Theo dõi chuột có đang trong vùng nút hoặc dropdown không
  bool _mouseInButton = false;
  bool _mouseInDropdown = false;

  // Cache dữ liệu Firestore (dùng chung cho tất cả instance)
  static List<String>? _cachedProducts;
  static List<String>? _cachedBrands;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  bool get _isMouseOver => _mouseInButton || _mouseInDropdown;

  void _cancelHide() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_isMouseOver) _removeOverlay();
    });
  }

  Future<List<String>> _fetchItems() async {
    if (widget.dropdownType == DropdownType.products) {
      if (_cachedProducts != null) return _cachedProducts!;
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .limit(15)
          .get();
      _cachedProducts = snap.docs
          .map((d) => d.data()['name']?.toString() ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      return _cachedProducts!;
    } else {
      if (_cachedBrands != null) return _cachedBrands!;
      final snap = await FirebaseFirestore.instance
          .collection('products')
          .get();
      final seen = <String>{};
      final brands = <String>[];
      for (final doc in snap.docs) {
        final cat = doc.data()['categoryName']?.toString() ?? '';
        if (cat.isNotEmpty && seen.add(cat)) brands.add(cat);
      }
      _cachedBrands = brands;
      return _cachedBrands!;
    }
  }

  void _showOverlay() async {
    // Overlay đã có → chỉ huỷ timer ẩn
    if (_overlayEntry != null) {
      _cancelHide();
      return;
    }

    final RenderBox box = _key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    final items = await _fetchItems();

    // ★ ĐIỂM MẤU CHỐT: sau khi fetch xong, kiểm tra chuột vẫn còn hover không
    // Nếu người dùng đã di chuột đi trong lúc đang fetch → không hiện overlay
    if (!mounted || !_isMouseOver) return;

    _cancelHide();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx - 20,
        top: offset.dy + size.height,
        child: MouseRegion(
          onEnter: (_) {
            _mouseInDropdown = true;
            _cancelHide();
          },
          onExit: (_) {
            _mouseInDropdown = false;
            _scheduleHide();
          },
          child: _DropdownMenu(items: items),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      key: _key,
      onEnter: (_) {
        _mouseInButton = true;
        _cancelHide();
        _showOverlay();
      },
      onExit: (_) {
        _mouseInButton = false;
        _scheduleHide();
      },
      child: TextButton(
        onPressed: widget.onTap,
        child: FutureBuilder<ui.Image>(
          future: widget.imageFuture,
          builder: (context, snapshot) {
            final textWidget = Text(
              widget.label,
              style: GoogleFonts.kavoon(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            );

            if (snapshot.connectionState != ConnectionState.done ||
                snapshot.hasError) {
              return textWidget;
            }

            final image = snapshot.data!;
            return ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final matrix = Matrix4.identity()
                  ..scale(
                    bounds.width / image.width,
                    bounds.height / image.height,
                  );
                return ImageShader(
                  image,
                  TileMode.clamp,
                  TileMode.clamp,
                  matrix.storage,
                );
              },
              child: textWidget,
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
//  Dropdown menu UI
// ─────────────────────────────────────────────────────────
class _DropdownMenu extends StatelessWidget {
  final List<String> items;

  const _DropdownMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        width: 220,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.asMap().entries.map((entry) {
              final isLast = entry.key == items.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      // TODO: navigate khi click item, ví dụ:
                      // Navigator.push(context, MaterialPageRoute(
                      //   builder: (_) => ProductListPage(filter: entry.value),
                      // ));
                    },
                    hoverColor: Colors.purple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: Colors.grey.shade200,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
// kết hợp với trên đầu để chuột vào nó sẽ hiện bảng lên . sau khi làm trang chính thì nó sẽ sửa thành tích vào đó ở trang detile .