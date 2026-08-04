import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Future<ui.Image> _imageFuture;
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _imageFuture = loadImage();
    video();
    animaten1();
  }

  void video() async {
    try {
      _controller = VideoPlayerController.asset('assets/videos/video.mp4');

      await _controller.initialize();

      await _controller.setLooping(true);

      await _controller.setVolume(0);

      await _controller.play();

      setState(() {
        _ready = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<ui.Image> loadImage() async {
    final data = await rootBundle.load('assets/images/text1.jpg');
    final codec = await ui.instantiateImageCodec(Uint8List.view(data.buffer));
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void animaten1() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    controller.repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Phát hiện điện thoại hay máy tính ────────────────────────────────
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        return isMobile ? _buildMobile() : _buildDesktop();
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // LAYOUT MÁY TÍNH — giữ nguyên như code gốc
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildDesktop() {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        height: 650,
        child: Stack(
          children: [
            Positioned(
              child: SizedBox(
                width: double.infinity,

                height: 150,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),

            SingleChildScrollView(
              child: Column(
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
                      if (snapshot.connectionState != ConnectionState.done)
                        return const CircularProgressIndicator();
                      if (snapshot.hasError) return const Text("Lỗi load ảnh");
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

                  Container(
                    padding: const EdgeInsets.only(top: 50),
                    width: double.infinity,
                    height: 280,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "GIỚI THIỆU",
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
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 100,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Liên hệ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Tin tức',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        231,
                                        215,
                                        215,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "CHÍNH SÁCH",
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
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 100,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Chính sách và quy định chung',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Quy định và hình thức thanh toán',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Chính sách vận chuyển và giao hàng',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        251,
                                        250,
                                        250,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "CÁC ĐIỂM BÁN HÀNG",
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
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 100,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'An Xuyên 2 , Mỹ Chánh , Phù Mỹ , Bình Định',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        252,
                                        250,
                                        250,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'An Xuyên 2 , Mỹ Chánh , Phù Mỹ , Bình Định',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Mở cửa : 8:30am ~ 5:30pm mỗi ngày ',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        254,
                                        254,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "TỔNG ĐÀI TƯ VẤN",
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
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: 100,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'Hotline: 0364-273-884',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                        colors: [
                                          ui.Color.fromARGB(255, 0, 100, 181),
                                          ui.Color.fromARGB(255, 91, 1, 107),
                                          ui.Color.fromARGB(255, 55, 0, 156),
                                        ],
                                      ).createShader(bounds),
                                  child: const Text(
                                    'CSKH: 0364-273-884',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        252,
                                        251,
                                        251,
                                      ),
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(
                        color: Color(0x33FFFFFF),
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      const SizedBox(height: 6),

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
                      const SizedBox(height: 10),
                      FutureBuilder<ui.Image>(
                        future: _imageFuture,
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
                              "Tân Thiên phát",
                              style: GoogleFonts.kavoon(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () => {},
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                ui.Color.fromARGB(255, 0, 100, 181),
                                ui.Color.fromARGB(255, 91, 1, 107),
                                ui.Color.fromARGB(255, 55, 0, 156),
                              ],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Chất lượng dịch vụ luôn là ưu tiên hàng đầu của chúng tôi.',
                            style: TextStyle(
                              color: ui.Color.fromARGB(255, 252, 251, 251),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // LAYOUT ĐIỆN THOẠI — 2×2 dọc, font và icon nhỏ hơn
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Container(
        width:
            double.infinity, // ← chiều rộng (double.infinity = full màn hình)
        height: 800, // ← chiều cao video, tăng/giảm số này
        child: Stack(
          children: [
            Image.asset(
              'assets/images/t.jpg',
              width: double.infinity,
              height: 800,
              fit: BoxFit.cover,
            ),
            // ─────────────────────────────────────────────────────────────
            SingleChildScrollView(
              child: Column(
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
                      if (snapshot.connectionState != ConnectionState.done)
                        return const CircularProgressIndicator();
                      if (snapshot.hasError) return const Text("Lỗi load ảnh");
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
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 220,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "GIỚI THIỆU",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Container(
                                width: 20,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),

                              TextButton(
                                onPressed: () {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Liên hệ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Tin tức',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        231,
                                        215,
                                        215,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "CHÍNH SÁCH",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Container(
                                width: 20,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Chính sách và quy định chung',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Quy định và hình thức thanh toán',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Chính sách vận chuyển và giao hàng',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        251,
                                        250,
                                        250,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 250,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "CÁC ĐIỂM BÁN HÀNG",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Container(
                                width: 20,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'An Xuyên 2 , Mỹ Chánh , Phù Mỹ , Bình Định',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        252,
                                        250,
                                        250,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'An Xuyên 2 , Mỹ Chánh , Phù Mỹ , Bình Định',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Mở cửa : 8:30am ~ 5:30pm mỗi ngày ',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        254,
                                        254,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () => {},
                                child: FutureBuilder<ui.Image>(
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
                                      child: const Text(
                                        "TỔNG ĐÀI TƯ VẤN",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              Container(
                                width: 20,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'Hotline: 0364-273-884',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              TextButton(
                                onPressed: () => {},
                                child: ShaderMask(
                                  shaderCallback: (bounds) {
                                    return const LinearGradient(
                                      colors: [
                                        ui.Color.fromARGB(255, 0, 100, 181),
                                        ui.Color.fromARGB(255, 91, 1, 107),
                                        ui.Color.fromARGB(255, 55, 0, 156),
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: const Text(
                                    'CSKH: 0364-273-884',
                                    style: TextStyle(
                                      color: ui.Color.fromARGB(
                                        255,
                                        252,
                                        251,
                                        251,
                                      ),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(
                        color: Color(0x33FFFFFF),
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      const SizedBox(height: 6),

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
                      const SizedBox(height: 10),
                      FutureBuilder<ui.Image>(
                        future: _imageFuture,
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
                              "Tân Thiên phát",
                              style: GoogleFonts.kavoon(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          );
                        },
                      ),
                      TextButton(
                        onPressed: () => {},
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return const LinearGradient(
                              colors: [
                                ui.Color.fromARGB(255, 0, 100, 181),
                                ui.Color.fromARGB(255, 91, 1, 107),
                                ui.Color.fromARGB(255, 55, 0, 156),
                              ],
                            ).createShader(bounds);
                          },
                          child: const Text(
                            'Chất lượng dịch vụ luôn là ưu tiên hàng đầu của chúng tôi.',
                            style: TextStyle(
                              color: ui.Color.fromARGB(255, 252, 251, 251),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
