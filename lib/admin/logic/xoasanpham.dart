import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// DỊCH VỤ XÓA SẢN PHẨM
// Cung cấp 2 hàm tĩnh:
//   - deleteOne  : xóa 1 sản phẩm theo docId
//   - deleteAll  : xóa toàn bộ sản phẩm trong collection
// =============================================================================
class DeleteProductService {
  DeleteProductService._(); // Không cho khởi tạo

  // ---------------------------------------------------------------------------
  // XÓA 1 SẢN PHẨM
  // ---------------------------------------------------------------------------
  static Future<void> deleteOne({
    required BuildContext context,
    required String docId,
    required String tenSanPham,
  }) async {
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Xóa sản phẩm',
      content:
          'Bạn có chắc muốn xóa sản phẩm\n"$tenSanPham" không?\n\nHành động này không thể hoàn tác.',
      confirmLabel: 'Xóa',
      confirmColor: Colors.red,
      icon: Icons.delete_outline,
    );
    if (!confirm) return;

    try {
      await FirebaseFirestore.instance
          .collection('sanpham')
          .doc(docId)
          .delete();

      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Đã xóa sản phẩm "$tenSanPham" thành công!',
        Colors.green.shade600,
        Icons.check_circle,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Lỗi khi xóa: $e',
        Colors.red,
        Icons.error_outline,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // XÓA TẤT CẢ SẢN PHẨM
  // ---------------------------------------------------------------------------
  static Future<void> deleteAll({required BuildContext context}) async {
    final confirm = await _showConfirmDialog(
      context: context,
      title: 'Xóa tất cả sản phẩm',
      content:
          'Hành động này sẽ xóa TOÀN BỘ sản phẩm và không thể hoàn tác.\n\nBạn có chắc chắn không?',
      confirmLabel: 'Xóa tất cả',
      confirmColor: Colors.red.shade700,
      icon: Icons.delete_sweep_outlined,
    );
    if (!confirm) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sanpham')
          .get();

      if (snapshot.docs.isEmpty) {
        if (!context.mounted) return;
        _showSnackBar(
          context,
          'Không có sản phẩm nào để xóa.',
          Colors.orange,
          Icons.info_outline,
        );
        return;
      }

      // Dùng batch để xóa cùng lúc, tối đa 500 docs mỗi batch
      final batches = <WriteBatch>[];
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        count++;
        if (count == 499) {
          batches.add(batch);
          batch = FirebaseFirestore.instance.batch();
          count = 0;
        }
      }
      if (count > 0) batches.add(batch);

      for (final b in batches) {
        await b.commit();
      }

      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Đã xóa tất cả ${snapshot.docs.length} sản phẩm!',
        Colors.green.shade600,
        Icons.check_circle,
      );
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(
        context,
        'Lỗi khi xóa tất cả: $e',
        Colors.red,
        Icons.error_outline,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // HỘP THOẠI XÁC NHẬN
  // ---------------------------------------------------------------------------
  static Future<bool> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: confirmColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: confirmColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: confirmColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          // Nút Hủy
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          // Nút Xác nhận xóa
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: Icon(icon, size: 15, color: Colors.white),
            label: Text(
              confirmLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // SNACKBAR THÔNG BÁO
  // ---------------------------------------------------------------------------
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
