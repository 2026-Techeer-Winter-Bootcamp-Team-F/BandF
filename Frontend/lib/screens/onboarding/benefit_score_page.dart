import 'package:flutter/material.dart';

class BenefitScorePage extends StatefulWidget {
  final int score; // 0..100
  final int received;
  final int missed;

  const BenefitScorePage({super.key, this.score = 85, this.received = 15240, this.missed = 3215});

  @override
  State<BenefitScorePage> createState() => _BenefitScorePageState();
}

class _BenefitScorePageState extends State<BenefitScorePage> {
  // 더미 지갑 카드 리스트 (홈 탭에 표시)
  final List<Map<String, String>> _walletCards = [
    {'bank': '신한', 'last4': '5699', 'color': '0xFFECEFF1'},
    {'bank': '토스', 'last4': '5289', 'color': '0xFFEFFB3'},
    {'bank': '비씨', 'last4': '7892', 'color': '0xFFF1F5F9'},
    {'bank': '국민', 'last4': '2095', 'color': '0xFFB0BEC5'},
  ];

  int _hoveredCard = -1;
  @override
  void initState() {
    super.initState();
    // 이 페이지는 이제 메인 내에서 탭 콘텐츠로 사용됩니다.
    // 외부에서 직접 푸시할 때 자동 이동이 필요하면 auth 흐름에서 MainNavigation을 푸시하세요.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text('${widget.score}', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              const Text('/100', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 18),
              const Text('나의 혜택 점수', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('**님이 사용하시는 카드 혜택의 85%를 챙기고 있어요', style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(child: _statCard('받은 혜택', widget.received, accent: Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('놓친 혜택', widget.missed, accent: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: 20),

              // 홈 탭에 보여질 카드 스택 추가
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: _buildCardStack(),
              ),
            ],
          ),
        ),
      ),
      // 하단 네비게이션은 이제 `MainNavigation`에서 관리합니다.
    );
  }

  Widget _statCard(String title, int amount, {Color? accent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(_formatWon(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent ?? Colors.black)),
            ],
          ),
        ],
      ),
    );
  }

  // 카드 스택 위젯
  Widget _buildCardStack() {
    final cardHeight = 70.0; // 절반 크기
    final overlap = 11.0; // 카드 간 겹침 간격도 절반

    return SizedBox(
      height: cardHeight + (_walletCards.length - 1) * overlap,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(_walletCards.length, (i) {
          final idx = _walletCards.length - 1 - i;
          final data = _walletCards[idx];
          final topOffset = i * overlap;
          final isHovered = _hoveredCard == idx;

          return Positioned(
            left: 0,
            right: 0,
            top: topOffset,
            child: MouseRegion(
              onEnter: (_) => setState(() => _hoveredCard = idx),
              onExit: (_) => setState(() => _hoveredCard = -1),
              child: GestureDetector(
                onTapDown: (_) => setState(() => _hoveredCard = idx),
                onTapUp: (_) => Future.delayed(const Duration(milliseconds: 180), () => setState(() => _hoveredCard = -1)),
                onTapCancel: () => setState(() => _hoveredCard = -1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.identity()..scale(isHovered ? 1.04 : 1.0),
                  transformAlignment: Alignment.center,
                  child: Container(
                    height: cardHeight,
                    decoration: BoxDecoration(
                      color: Color(int.parse(data['color']!)),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 4))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text('${data['bank']}카드', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                const Spacer(),
                                Text('•••• ${data['last4']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), borderRadius: BorderRadius.circular(12)),
                            child: Text('${data['bank']} ${data['last4']}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatWon(int value) {
    final s = value.toString();
    final out = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return '₩$out';
  }
}
