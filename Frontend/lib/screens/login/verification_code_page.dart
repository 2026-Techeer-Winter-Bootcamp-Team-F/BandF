import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/screens/login/password_page.dart';

class VerificationCodePage extends StatefulWidget {
  final String phone;
  final String name;
  const VerificationCodePage({super.key, required this.phone, required this.name});

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _timer;
  int _seconds = 180;
  bool _sending = false;

  bool get _codeComplete => RegExp(r'^\d{6}$').hasMatch(_codeController.text.trim());

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendSms();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 180);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_seconds <= 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  Future<void> _sendSms() async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('인증번호가 발송되었습니다.')));
  }

  void _onResend() {
    _startTimer();
    _sendSms();
  }

  void _onConfirm() {
    if (!_codeComplete) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PasswordPage(phone: widget.phone, name: widget.name)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  String _formatTimer() {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('문자로 전송된\n인증번호 6자리를 입력해주세요.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        hintText: '6자리 숫자',
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_formatTimer(), style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _seconds == 0 ? _onResend : null,
                child: Text(_seconds == 0 ? '인증번호 재전송' : '인증번호가 안와요', style: TextStyle(color: _seconds == 0 ? theme.primaryColor : Colors.grey)),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _codeComplete ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}