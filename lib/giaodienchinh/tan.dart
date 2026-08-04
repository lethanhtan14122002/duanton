import 'package:duanton/ui/duoi.dart';
import 'package:duanton/ui/trendau.dart';
import 'package:flutter/material.dart';

// ── Widget chính: chọn layout theo màn hình ──
class Tan extends StatelessWidget {
  const Tan({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 600;
        return isMobile ? const TanMobile() : const TanDesktop();
      },
    );
  }
}

// ── Layout điện thoại ──
class TanMobile extends StatelessWidget {
  const TanMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/1.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(
          padding: const EdgeInsets.only(top: 105),
          child: SingleChildScrollView(
            child: Column(children: [FooterWidget()]),
          ),
        ),
        Trendau(),
      ],
    );
  }
}

// ── Layout laptop / desktop ──
class TanDesktop extends StatelessWidget {
  const TanDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/images/1.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Container(
          padding: const EdgeInsets.only(top: 230),
          child: SingleChildScrollView(
            child: Column(children: [FooterWidget()]),
          ),
        ),
        Trendau(),
      ],
    );
  }
}
