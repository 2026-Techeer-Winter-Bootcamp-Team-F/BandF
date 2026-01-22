import 'package:flutter/material.dart';
import 'package:my_app/screens/login/verification_code_page.dart';

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fieldsSlideAnimation;
  late Animation<double> _newFieldFadeAnimation;
  
  bool _showSsnField = false;
  bool _showPhoneField = false;
  bool _nameConfirmed = false;
  bool _ssnConfirmed = false;
  String? _selectedCarrier;

  bool get _canProceedName => _nameController.text.trim().isNotEmpty;
  bool get _frontValid => RegExp(r'^\d{6}$').hasMatch(_frontController.text);
  bool get _backValid => RegExp(r'^\d$').hasMatch(_backController.text);
  bool get _canConfirmSsn => _frontValid && _backValid;
  bool get _phoneValid => RegExp(r'^\d{10,11}$').hasMatch(_phoneController.text.trim());
  bool get _canConfirmPhone => _phoneValid && _selectedCarrier != null;

  final List<String> _carriers = [
    'SKT',
    'KT',
    'LG U+',
    'SKT 알뜰폰',
    'KT 알뜰폰',
    'LG U+ 알뜰폰',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fieldsSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _newFieldFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _frontController.dispose();
    _backController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNameConfirm() {
    if (!_canProceedName || _nameConfirmed) return;
    
    setState(() {
      _nameConfirmed = true;
      _showSsnField = true;
    });
    
    _animationController.forward();
  }

  void _onSsnConfirm() {
    if (!_canConfirmSsn || _ssnConfirmed) return;
    _showCarrierSheet();
  }

  void _onPhoneConfirm() {
    if (!_canConfirmPhone) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationCodePage(
          phone: _phoneController.text.trim(),
          name: _nameController.text.trim(),
        ),
      ),
    );
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

    if (selected != null && mounted) {
      setState(() {
        _selectedCarrier = selected;
        _ssnConfirmed = true;
        _showPhoneField = true;
      });
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

  Widget _maskedSsnRow() {
    return Row(
      children: [
        Text(_frontController.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        const Text('-', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(_backController.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    
    String title = '이름을 입력해주세요.';
    if (_ssnConfirmed) {
      title = '휴대폰 번호를 입력해주세요.';
    } else if (_nameConfirmed) {
      title = '주민등록번호를 입력해주세요.';
    }
    
    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  
                  // 전화번호 입력 필드 (애니메이션)
                  if (_showPhoneField) ...[
                    Opacity(
                      opacity: _newFieldFadeAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '휴대폰 번호',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '01012345678',
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: theme.primaryColor, width: 2),
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                  
                  // 통신사 (선택됨)
                  if (_ssnConfirmed && _selectedCarrier != null) ...[
                    Transform.translate(
                      offset: Offset(0, _fieldsSlideAnimation.value),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '통신사',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                _selectedCarrier!,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                  
                  // 주민등록번호 입력 필드 또는 표시
                  if (_showSsnField) ...[
                    Transform.translate(
                      offset: Offset(0, _ssnConfirmed ? _fieldsSlideAnimation.value : 0),
                      child: _ssnConfirmed 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '주민등록번호',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              _maskedSsnRow(),
                              const SizedBox(height: 12),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '주민등록번호',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _buildFrontField(theme),
                                  const SizedBox(width: 8),
                                  const Text('-', style: TextStyle(fontSize: 18, color: Colors.black)),
                                  const SizedBox(width: 8),
                                  _buildBackInputAndMask(theme),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                    ),
                  ],
                  
                  // 이름 입력 필드 (이동 애니메이션)
                  Transform.translate(
                    offset: Offset(0, (_nameConfirmed ? _fieldsSlideAnimation.value : 0) + 
                                      (_ssnConfirmed ? _fieldsSlideAnimation.value : 0)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '이름',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        _nameConfirmed
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _nameController.text,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          : TextField(
                              controller: _nameController,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: '',
                                suffixIcon: _nameController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () => setState(() => _nameController.clear()),
                                      )
                                    : null,
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: theme.primaryColor, width: 2),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _onNameConfirm(),
                            ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ssnConfirmed
                          ? (_canConfirmPhone ? _onPhoneConfirm : null)
                          : _nameConfirmed
                              ? (_canConfirmSsn ? _onSsnConfirm : null)
                              : (_canProceedName ? _onNameConfirm : null),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('확인'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}