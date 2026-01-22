import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:my_app/config/theme.dart';
import 'package:my_app/screens/splash/splash_page.dart';

void main() {
  // 웹에서 Google Fonts 자동 로딩 방지
  if (kIsWeb) {
    // 웹 환경에서 추가 설정이 필요한 경우 여기에 작성
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeneFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashPage(),
    );
  }
}