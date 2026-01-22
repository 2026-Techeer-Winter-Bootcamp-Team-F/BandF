import 'package:flutter/material.dart';
import 'package:my_app/screens/login/confirm_signup_page.dart';

class SsnInputPage extends StatefulWidget {
  final String name;
  const SsnInputPage({super.key, required this.name});

  @override
  State<SsnInputPage> createState() => _SsnInputPageState();
}

class _SsnInputPageState extends State<SsnInputPage> {
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  bool get _frontValid => RegExp(r'^\d{6}$').hasMatch(_frontController.text);
  bool get _backValid => RegExp(r'^\d$').hasMatch(_backController.text);
  bool get _canConfirm => _frontValid && _backValid;

  final List<String> _carriers = [
    'SKT',
    'KT',
    'LG U+',
    'SKT 알뜰폰',
    'KT 알뜰폰',
    'LG U+ 알뜰폰',
  ];

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!_canConfirm) return;
    _showCarrierSheet();
  }

  Future<void> _showCarrierSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    children: [
                      const Text('통신사 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _carriers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _carriers[index];
                      return ListTile(
                        title: Text(item),
                        onTap: () {
                          Navigator.of(context).pop(item);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      // 통신사 선택 완료 → 정보 확인(휴대폰 입력) 화면으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConfirmSignupPage(
            name: widget.name,
            ssnFront: _frontController.text,
            ssnBackFirst: _backController.text,
            carrier: selected,
          ),
        ),
      );
    }
  }

  Widget _buildFrontField(ThemeData theme) {
    return Expanded(
      child: TextField(
        controller: _frontController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        decoration: InputDecoration(
          counterText: '',
          hintText: '앞 6자리',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildBackInputAndMask(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          child: TextField(
            controller: _backController,
            keyboardType: TextInputType.number,
            maxLength: 1,
            obscureText: true,
            decoration: InputDecoration(
              counterText: '',
              hintText: '',
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: List.generate(6, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                '주민등록번호를 입력해주세요.',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 18),
              Text(
                '주민등록번호',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildFrontField(theme),
                  const SizedBox(width: 8),
                  const Text('-', style: TextStyle(fontSize: 18, color: Colors.black)),
                  const SizedBox(width: 8),
                  _buildBackInputAndMask(theme),
                ],
              ),
              const SizedBox(height: 18),
              Text('이름: ${widget.name}', style: const TextStyle(color: Colors.grey)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canConfirm ? _onConfirm : null,
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