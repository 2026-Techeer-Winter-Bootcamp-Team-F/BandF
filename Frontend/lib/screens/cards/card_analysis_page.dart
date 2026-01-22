import 'package:flutter/material.dart';
import 'package:my_app/screens/cards/card_detail_page.dart';
import 'package:my_app/services/card_service.dart';
import 'package:my_app/models/user_card.dart';

class CardAnalysisPage extends StatefulWidget {
  const CardAnalysisPage({super.key});

  @override
  State<CardAnalysisPage> createState() => _CardAnalysisPageState();
}

class _CardAnalysisPageState extends State<CardAnalysisPage> {
  final CardService _cardService = CardService();
  List<UserCard>? _userCards;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final cards = await _cardService.getMyCards();
      setState(() {
        _userCards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '카드 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Title intentionally left blank per UI request
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadCards,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : _userCards == null || _userCards!.isEmpty
          ? const Center(child: Text('등록된 카드가 없습니다'))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wallet stack (full width inside padding)
                      SizedBox(
                        width: double.infinity,
                        height: _userCards!.length * 40.0 + 160.0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(_userCards!.length, (i) {
                            final card = _userCards![i];
                            final offset = i * 40.0;
                            return Positioned(
                              top: offset,
                              left: 0,
                              right: 0,
                              child: _buildCard(
                                context,
                                card,
                                i == _userCards!.length - 1,
                              ),
                            );
                          }),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Header text like the screenshot (left-aligned)
                      const Text(
                        '이 카드는 어때요?',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        '3개월 동안의 가장 많이 쓴 카테고리 소비 평균에 따른 실익률을 분석했어요.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 18),

                      // Recommendation sections
                      Column(
                        children: _recommendations
                            .map(
                              (section) =>
                                  _buildRecommendationSection(context, section),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Sample recommendation data: category, totalSpent, recommended cards
  static final List<Map<String, dynamic>> _recommendations = [
    {
      'category': '택시',
      'total': 27133,
      'items': [
        {
          'image': 'assets/cards/card1.png',
          'title': '현대카드',
          'subtitle': '연회비: 20만 원',
          'percent': '110%',
        },
        {
          'image': 'assets/cards/card2.png',
          'title': 'BC카드',
          'subtitle': '연회비: 20만 원',
          'percent': '110%',
        },
        {
          'image': 'assets/cards/card3.png',
          'title': '롯데카드',
          'subtitle': '연회비: 20만 원',
          'percent': '230%',
        },
        {
          'image': 'assets/cards/card4.png',
          'title': 'Mr.Life',
          'subtitle': '연회비: 20만 원',
          'percent': '190%',
        },
      ],
    },
    {
      'category': '교통',
      'total': 7816,
      'items': [
        {
          'image': 'assets/cards/card1.png',
          'title': '현대카드',
          'subtitle': '연회비: 20만 원',
          'percent': 'ROI',
        },
        {
          'image': 'assets/cards/card2.png',
          'title': 'BC카드',
          'subtitle': '연회비: 20만 원',
          'percent': '110%',
        },
        {
          'image': 'assets/cards/card3.png',
          'title': '롯데카드',
          'subtitle': '연회비: 20만 원',
          'percent': '95%',
        },
        {
          'image': 'assets/cards/card4.png',
          'title': '신한카드',
          'subtitle': '연회비: 20만 원',
          'percent': '130%',
        },
      ],
    },
    {
      'category': '마트',
      'total': 4500,
      'items': [
        {
          'image': 'assets/cards/card2.png',
          'title': '이마트카드',
          'subtitle': '연회비: 10만 원',
          'percent': '150%',
        },
        {
          'image': 'assets/cards/card3.png',
          'title': '롯데마트카드',
          'subtitle': '연회비: 12만 원',
          'percent': '140%',
        },
        {
          'image': 'assets/cards/card4.png',
          'title': '홈플러스카드',
          'subtitle': '연회비: 8만 원',
          'percent': '125%',
        },
        {
          'image': 'assets/cards/card1.png',
          'title': '쿠팡카드',
          'subtitle': '연회비: 0원',
          'percent': '115%',
        },
      ],
    },
  ];

  Widget _buildRecommendationSection(
    BuildContext context,
    Map<String, dynamic> section,
  ) {
    final items = section['items'] as List<dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              section['category'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              '총 ${_formatWon(section['total'] as int)} 썼어요',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.05,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: items
              .map(
                (it) => _RecommendationCard(data: it as Map<String, dynamic>),
              )
              .toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  String _formatWon(int value) {
    final s = value.toString();
    final out = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return '${out}원';
  }

  Widget _buildCard(BuildContext context, UserCard card, bool isBottom) {
    // 카드 번호에서 마지막 4자리 추출
    final last4Digits =
        card.cardNumber.isNotEmpty && card.cardNumber.length >= 4
        ? card.cardNumber.substring(card.cardNumber.length - 4)
        : '';
    final cardLabel = '${card.company} ${last4Digits}';

    // 회사명으로 색상 지정 (기본값)
    Color cardColor = _getCardColor(card.company);

    return GestureDetector(
      onTap: () {
        // 필요시 카드 상세 페이지로 이동
        // Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardDetailPage(card: card)));
      },
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // 카드 이미지 (네트워크 이미지)
            if (card.cardImageUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    card.cardImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // 이미지 로딩 실패 시 기본 UI 표시
                      return Container(color: cardColor);
                    },
                  ),
                ),
              ),
            // 칩 아이콘
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                width: 48,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // 카드 라벨 (우측 상단)
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  cardLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // 카드 정보 (좌측 하단)
            Positioned(
              left: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.cardName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.displayCardNumber.isNotEmpty
                        ? card.displayCardNumber
                        : card.company,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            // 오버레이 효과 (맨 위 카드가 아닐 경우)
            if (!isBottom)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 카드사별 색상 매핑
  Color _getCardColor(String company) {
    switch (company) {
      case '신한카드':
        return const Color(0xFF0046FF);
      case '현대카드':
        return const Color(0xFF000000);
      case '삼성카드':
        return const Color(0xFF1428A0);
      case 'KB국민카드':
        return const Color(0xFFFFB900);
      case '하나카드':
        return const Color(0xFF008485);
      case '우리카드':
        return const Color(0xFF0033A0);
      case '롯데카드':
        return const Color(0xFFED1C24);
      case 'NH농협카드':
        return const Color(0xFF4FA449);
      case 'BC카드':
      case '비씨카드':
        return const Color(0xFFE51937);
      case '토스뱅크':
        return const Color(0xFF0064FF);
      default:
        return const Color(0xFFECECEC);
    }
  }
}

// WalletCard 클래스는 더 이상 사용하지 않음 (삭제 가능)

class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RecommendationCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: Image.asset(
                data['image'] as String,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.credit_card,
                    size: 28,
                    color: Colors.black26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data['title'] as String,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  data['subtitle'] as String,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                data['percent'] as String,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
