import 'package:flutter/material.dart';

class PasswordConfirmPage extends StatefulWidget {
  final String password; // 최초 입력한 비밀번호 전달받음
  const PasswordConfirmPage({super.key, required this.password});

  @override
  State<PasswordConfirmPage> createState() => _PasswordConfirmPageState();
}

class _PasswordConfirmPageState extends State<PasswordConfirmPage> {
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  String? _errorText;

  // 동일한 비밀번호인지와 규칙(영문, 숫자, 특수문자, 최소 8자) 모두 검사
  final RegExp _pwRule = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$');

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  void _validate(String v) {
    if (v.isEmpty) {
      setState(() => _errorText = null);
      return;
    }
    if (!_pwRule.hasMatch(v)) {
      setState(() => _errorText = '영문, 숫자, 특수문자 조합 (최소 8자)');
      return;
    }
    if (v != widget.password) {
      setState(() => _errorText = '입력한 비밀번호와 일치하지 않습니다.');
      return;
    }
    setState(() => _errorText = null);
  }

  void _onConfirm() {
    if (_errorText != null) return;
    if (_confirmController.text.trim() == widget.password && _pwRule.hasMatch(widget.password)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('비밀번호가 확인되었습니다.')));
      Navigator.of(context).popUntil((route) => route.isFirst); // 완료 후 루트로 이동(필요시 변경)
    } else {
      _validate(_confirmController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canProceed = (_confirmController.text.isNotEmpty && _errorText == null && _pwRule.hasMatch(_confirmController.text) && _confirmController.text == widget.password);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                '최소 8자리 이상\n비밀번호를 재확인해주세요.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              const Text('비밀번호 재확인', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmController,
                obscureText: _obscure,
                onChanged: (v) {
                  _validate(v);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: '영문, 숫자, 특수문자 조합',
                  helperText: '영문, 숫자, 특수문자 조합',
                  errorText: _errorText,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor, width: 2)),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_confirmController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _confirmController.clear()),
                        ),
                      IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canProceed ? _onConfirm : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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