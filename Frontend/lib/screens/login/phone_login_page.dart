import 'package:flutter/material.dart';
import 'package:my_app/screens/login/login_password_page.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final TextEditingController _phoneController = TextEditingController();

  bool get _canProceed {
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      return RegExp(r'^\d{10,11}$').hasMatch(digits);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _next() {
    if (!_canProceed) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginPasswordPage(phone: _phoneController.text.trim())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '전화번호를 입력해주세요.',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              const Text('전화번호', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                onSubmitted: (_) => _next(),
                decoration: InputDecoration(
                  hintText: '01012345678',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                  suffixIcon: _phoneController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Container(
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF0F0F0)),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.clear, size: 18, color: Colors.grey),
                          ),
                          onPressed: () => setState(() => _phoneController.clear()),
                        ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _next : null,
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}