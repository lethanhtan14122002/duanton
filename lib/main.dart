import 'package:duanton/admin/ui/AddProductScreen.dart';
import 'package:duanton/admin/ui/sanpham.dart';
import 'package:duanton/firebase_options.dart';
import 'package:duanton/giaodienchinh/tan.dart';
import 'package:duanton/login/login.dart';
import 'package:duanton/ui/duoi.dart';
import 'package:duanton/ui/sanphamuudailaptop.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:duanton/ui/trendau.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ton());
}

class ton extends StatefulWidget {
  const ton({super.key});

  @override
  State<ton> createState() => _tonState();
}

class _tonState extends State<ton> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Website Thương mại',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: 'sanphamuudai',
      routes: {
        'trendau': (context) => Trendau(),
        'duoi': (context) => FooterWidget(),
        'giaodienchinh': (context) => Tan(),
        'login': (context) => AuthScreen(),
        'sanpham': (context) => AddProductScreen(),
        'showsanpham': (context) => ProductListScreen(),
        'sanphamuudai': (context) => SanPhamUuDaiSection(),
      },
    );
  }
}
