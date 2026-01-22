import 'package:flutter/material.dart';
import 'package:my_app/screens/main_navigation.dart';

class SignupCompletePage extends StatefulWidget {
  final String name;
  const SignupCompletePage({super.key, required this.name});

  @override
  State<SignupCompletePage> createState() => _SignupCompletePageState();
}

class _SignupCompletePageState extends State<SignupCompletePage> {
  @override
  void initState() {
    super.initState();
    // 2초 후 자동으로 메인 화면으로 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Center(child: FlutterLogo(size: 80)),
              const SizedBox(height: 40),
              const Text('로그인 완료!', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    const TextSpan(text: '님,\n', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    const TextSpan(text: '환영합니다!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}