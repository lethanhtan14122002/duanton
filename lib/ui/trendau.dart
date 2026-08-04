import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duanton/ui/nut_hover_nav_dropdown.dart';
import 'package:duanton/ux/product_detail_page.dart';
import 'package:duanton/ux/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class Trendau extends StatefulWidget {
  const Trendau({super.key});

  @override
  State<Trendau> createState() => _TrendauState();
}

class _TrendauState extends State<Trendau> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Future<ui.Image> _imageFuture;
  late Future<ui.Image> _imageFuture1;
  final TextEditingController searchController = TextEditingController();
  List<QueryDocumentSnapshot> products = [];
  bool loading = false;
  int currentImage = 0;
  Timer? timer;
  final List<String> images = [
    "assets/images/11.jpg",
    "assets/images/s1.jpg",
    "assets/images/s10.jpg",
    "assets/images/tuyet.jpg",
  ];

  @override
  void initState() {
    super.initState();
    _imageFuture = loadImage();
    _imageFuture1 = loadImage1();
    animaten1();
    moveimage();
  }

  void moveimage() {
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      setState(() {
        currentImage = (currentImage + 1) % images.length;
      });
    });
  }

  void animaten1() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    controller.repeat();
  }

  Future<ui.Image> loadImage() async {
    final data = await rootBundle.load('assets/images/text1.jpg');
    final codec = await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> loadImage1() async {
    final data = await rootBundle.load('assets/images/text1.jpg');
    final codec = await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<void> searchProduct(String keyword) async {
    keyword = keyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      setState(() {
        products = [];
      });
      return;
    }
    setState(() {
      loading = true;
    });

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("products")
        .get();

    List<QueryDocumentSnapshot> result = snapshot.docs.where((doc) {
      String name = doc["name"].toString().toLowerCase();
      return name.contains(keyword);
    }).toList();

    setState(() {
      products = result;
      loading = false;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    controller.dispose();
    timer?.cancel();
    super.dispose();
  }

  Widget buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: 70,
          height: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image, size: 60),
        );
      } catch (e) {
        return const Icon(Icons.image, size: 60);
      }
    }
    return Image.network(
      imageUrl,
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image, size: 60),
    );
  }

  // ── HEADER MÁY TÍNH (>= 600px) ──
  Widget buildDesktopHeader() {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: AssetImage(images[currentImage]),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // ── HEADER ──
            SizedBox(
              width: double.infinity,
              height: 146,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: controller.value * 2 * 3.14159,
                              child: child,
                            );
                          },
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 54,
                            height: 54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<ui.Image>(
                          future: _imageFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done)
                              return const CircularProgressIndicator();
                            if (snapshot.hasError)
                              return const Text("Lỗi load ảnh");
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
                              child: Text(
                                "Tân Thiên phát",
                                style: GoogleFonts.kavoon(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      child: TextField(
                        controller: searchController,
                        onChanged: searchProduct,
                        decoration: InputDecoration(
                          hintText: "Bạn tìm gì ...",
                          labelText: 'SEARCH',
                          hintStyle: const TextStyle(
                            color: ui.Color.fromARGB(136, 28, 27, 27),
                            fontSize: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(
                              color: Colors.grey,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: const BorderSide(
                              color: Colors.blue,
                              width: 3,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(15),
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.black54,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.only(left: 30),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: ui.Color.fromARGB(255, 0, 0, 0),
                            size: 60,
                          ),
                          Text(
                            '0364-270-884',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 50),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          minimumSize: const Size(50, 60),
                          elevation: 3,
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Giỏ Hàng',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(width: 5),
                            Icon(
                              Icons.shopping_cart,
                              color: Colors.black,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      child: FutureBuilder<ui.Image>(
                        future: _imageFuture1,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError)
                            return const Text("Lỗi load ảnh");
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
                            child: Text(
                              "TRANG CHỦ",
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => day2()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: HoverNavItem(
                      label: "SẢN PHẨM",
                      imageFuture: _imageFuture1,
                      dropdownType: DropdownType.products,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => day2()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: HoverNavItem(
                      label: "Thương hiệu",
                      imageFuture: _imageFuture1,
                      dropdownType: DropdownType.brands,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => day2()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      child: FutureBuilder<ui.Image>(
                        future: _imageFuture1,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError)
                            return const Text("Lỗi load ảnh");
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
                            child: Text(
                              "SẢN PHẨM BÁN CHẠY",
                              style: GoogleFonts.kavoon(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => day2()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      child: FutureBuilder<ui.Image>(
                        future: _imageFuture1,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError)
                            return const Text("Lỗi load ảnh");
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
                            child: Text(
                              "ƯU ĐÃI",
                              style: GoogleFonts.kavoon(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => day2()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      child: FutureBuilder<ui.Image>(
                        future: _imageFuture1,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState != ConnectionState.done)
                            return const CircularProgressIndicator();
                          if (snapshot.hasError)
                            return const Text("Lỗi load ảnh");
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
                            child: Text(
                              "LIÊN HỆ",
                              style: GoogleFonts.kavoon(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => day2()),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      onPressed: () => {},
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.black,
                        size: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // ── SEARCH RESULTS ĐÃ BỊ XÓA KHỎI ĐÂY ──
            // Kết quả tìm kiếm được hiển thị trong build() bên dưới
          ],
        ),
      ),
    );
  }

  // ── HEADER ĐIỆN THOẠI (< 600px) ──
  Widget buildMobileHeader() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(images[currentImage]),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Nút 3 gạch → mở menu điều hướng ──
              Builder(
                builder: (context) => IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Menu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(height: 20),
                            ListTile(
                              leading: const Icon(
                                Icons.home_outlined,
                                color: Colors.black87,
                              ),
                              title: Text(
                                'TRANG CHỦ',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => day2(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.black87,
                              ),
                              title: Text(
                                'SẢN PHẨM',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => day2(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.branding_watermark_outlined,
                                color: Colors.black87,
                              ),
                              title: Text(
                                'Thương hiệu',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => day2(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.local_fire_department_outlined,
                                color: Colors.orange,
                              ),
                              title: Text(
                                'SẢN PHẨM BÁN CHẠY',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => day2(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.discount_outlined,
                                color: Colors.red,
                              ),
                              title: Text(
                                'ƯU ĐÃI',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => day2(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.phone_outlined,
                                color: Colors.green,
                              ),
                              title: Text(
                                'LIÊN HỆ',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => day2(),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.person_outline,
                                color: Colors.black87,
                                size: 28,
                              ),
                              title: Text(
                                'TÀI KHOẢN',
                                style: GoogleFonts.kavoon(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Divider(height: 20),
                            const Row(
                              children: [
                                Icon(Icons.phone, color: Colors.green),
                                SizedBox(width: 10),
                                Text(
                                  '0364-270-884',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.red),
                                SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    'Địa chỉ cửa hàng của bạn',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu, size: 28, color: Colors.black),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),

              const SizedBox(width: 8),

              // ── Icon + Tên app ──
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: controller.value * 2 * 3.14159,
                        child: child,
                      );
                    },
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<ui.Image>(
                    future: _imageFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done)
                        return const SizedBox(height: 14);
                      if (snapshot.hasError)
                        return const Text(
                          "Tân Thiên phát",
                          style: TextStyle(fontSize: 10),
                        );
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
                        child: Text(
                          "Tân Thiên phát",
                          style: GoogleFonts.kavoon(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(width: 10),

              // ── Ô tìm kiếm ──
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: searchProduct,
                  decoration: InputDecoration(
                    hintText: "Bạn tìm gì ...",
                    hintStyle: const TextStyle(
                      color: ui.Color.fromARGB(136, 28, 27, 27),
                      fontSize: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    suffixIcon: const Icon(
                      Icons.search,
                      color: Colors.black54,
                      size: 22,
                    ),
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ── Giỏ hàng ──
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.shopping_cart,
                  size: 28,
                  color: Colors.black,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              // ── SEARCH RESULTS ĐÃ BỊ XÓA KHỎI ĐÂY ──
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;
          final double headerHeight = isMobile ? 100 : 220;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Lớp dưới: chỉ hiển thị header ──
              isMobile ? buildMobileHeader() : buildDesktopHeader(),

              // ── Lớp trên: kết quả tìm kiếm nổi đè lên ──
              if (loading)
                Positioned(
                  top: isMobile ? 62 : 155,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                )
              else if (products.isEmpty &&
                  searchController.text.trim().isNotEmpty)
                Positioned(
                  top: headerHeight,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "Không tìm thấy sản phẩm",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else if (products.isNotEmpty)
                Positioned(
                  top: headerHeight,
                  left: 0,
                  right: 0,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight:
                            constraints.maxHeight * 0.6, // tối đa 60% màn hình
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final doc = products[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: buildImage(
                                doc["imageUrl"]?.toString() ?? "",
                              ),
                              title: Text(
                                doc["name"]?.toString() ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                doc["price"]?.toString() ?? "",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                              onTap: () {
                                // Xóa kết quả và đóng dropdown khi chọn
                                setState(() {
                                  products = [];
                                  searchController.clear();
                                });
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailPage(
                                      product: products.isNotEmpty
                                          ? products[index]
                                          : doc,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
