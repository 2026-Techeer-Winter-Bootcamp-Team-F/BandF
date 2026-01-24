// [설명] 카드 분석 화면 - 사용자가 등록한 카드와 추천 카드 표시
// [수정사항] 백엔드 API에서 카드 데이터와 이미지 URL을 받아와서 표시하도록 변경
import 'package:flutter/material.dart';
import 'package:my_app/services/card_service.dart'; // [추가] 카드 서비스 import
import 'package:my_app/models/card.dart'; // [추가] 카드 모델 import
import 'package:my_app/widgets/card_image.dart'; // [추가] 카드 이미지 위젯 import
import 'package:my_app/screens/cards/card_detail_page.dart'; // [추가] 카드 상세 페이지 import

// [수정] StatelessWidget에서 StatefulWidget으로 변경 (API 호출을 위해)
class CardAnalysisPage extends StatefulWidget {
  const CardAnalysisPage({super.key});

  @override
  State<CardAnalysisPage> createState() => _CardAnalysisPageState();
}

class _CardAnalysisPageState extends State<CardAnalysisPage> {
  // [추가] 카드 서비스 인스턴스 생성
  final CardService _cardService = CardService();

  // [추가] 사용자 카드 리스트 (백엔드에서 가져옴)
  List<CreditCard> _userCards = [];

  // [추가] 추천 카드 리스트 (백엔드에서 가져옴)
  List<CreditCard> _recommendedCards = [];

  // [추가] 로딩 상태 관리
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // [추가] 화면 초기화 시 카드 데이터 로드
    _loadCards();
  }

  // [추가] 백엔드에서 카드 데이터를 가져오는 메서드
  Future<void> _loadCards() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // [설명] 백엔드 API를 호출하여 사용자 카드와 추천 카드 동시에 가져오기
      final results = await Future.wait([
        _cardService.getMyCards(), // 사용자가 등록한 카드 목록
        _cardService.getRecommendedCards(), // 추천 카드 목록
      ]);

      setState(() {
        _userCards = results[0]; // 사용자 카드
        _recommendedCards = results[1]; // 추천 카드
        _isLoading = false;
      });
    } catch (e) {
      // [설명] API 호출 실패 시 에러 처리
      print('카드 로드 에러: $e'); // 디버깅용 로그
      setState(() {
        _isLoading = false;
      });

      // [설명] 에러 발생 시 사용자에게 안내
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카드 정보를 불러오지 못했습니다: ${e.toString()}')),
        );
      }
    }
  }

  // [추가] 더미 데이터 로드 (백엔드 연결 실패 시 폴백용)
  void _loadDummyCards() {
    setState(() {
      // 더미 카드 데이터는 원래 코드의 _cards 사용
      _userCards = []; // 실제로는 더미 데이터를 여기에 추가 가능
      _recommendedCards = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // [설명] 로딩 중일 때 로딩 인디케이터 표시
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Title intentionally left blank per UI request
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [수정] 백엔드 데이터 _userCards를 사용하여 카드 스택 표시
                SizedBox(
                  width: double.infinity,
                  height: 520,
                  child: _userCards.isEmpty
                      ? Center(
                          child: const Text(
                            '등록된 카드가 없습니다.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : Stack(
                          clipBehavior: Clip.none,
                          children: List.generate(_userCards.length, (i) {
                            final card = _userCards[i];
                            // Keep all visible cards the same scale/size.
                            final offset = i * 40.0;
                            final scale = 1.0;
                            return Positioned(
                              top: offset,
                              left: 0,
                              right: 0,
                              child: Transform.scale(
                                scale: scale,
                                alignment: Alignment.topCenter,
                                child: _buildCard(
                                  context,
                                  card,
                                  i == _userCards.length - 1,
                                ),
                              ),
                            );
                          }),
                        ),
                ),

                const SizedBox(height: 28),

                // Header text like the screenshot (left-aligned)
                const Text(
                  '이 카드는 어때요?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  '3개월 동안의 가장 많이 쓴 카테고리 소비 평균에 따른 실익률을 분석했어요.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 18),

                // [수정] 백엔드 추천 카드 데이터 _recommendedCards 사용
                _buildRecommendedCardsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // [추가] 추천 카드 섹션 빌드
  // [설명] 백엔드에서 받아온 추천 카드들을 그리드 레이아웃으로 표시
  Widget _buildRecommendedCardsSection() {
    if (_recommendedCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '추천 카드',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              '더 많은 추천을 받으려면 거래 내역을 기록해 주세요.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 카드',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.05,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _recommendedCards
              .map((card) => _RecommendedCardFromBackend(card: card))
              .toList(),
        ),
      ],
    );
  }

  // [추가] 금액을 원화 형식으로 표시하는 헬퍼 메서드
  // [설명] 1000단위 쉼표 추가 (예: 123456 → 123,456원)
  String _formatWon(int value) {
    final s = value.toString();
    final out = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return '${out}원';
  }

  // [수정] 백엔드 데이터 CreditCard를 받아서 카드 UI 빌드
  // [설명] WalletCard 대신 CreditCard 사용하여 백엔드 데이터 표시
  Widget _buildCard(BuildContext context, CreditCard card, bool isBottom) {
    return GestureDetector(
      // [설명] 카드 클릭 시 상세 페이지로 이동 (카드 정보 표시용)
      onTap: () {
        // [수정] CardDetailPage를 CreditCard 타입으로 수정
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => CardDetailPage(card: card)));
      },
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          // [설명] 백엔드에서 제공하는 색상 또는 기본값
          color: Colors.grey[200],
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
            // [설명] 카드 로고 영역
            Positioned(
              left: 20,
              top: 20,
              child: CardImageWidget(
                // [중요] 백엔드에서 받아온 이미지 URL 표시
                imageUrl: card.imageUrl,
                width: 48,
                height: 34,
                borderRadius: 6,
              ),
            ),
            // [설명] 카드 번호 배지 (우상단)
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
                  // [설명] 카드 이름 표시
                  card.name.length > 10
                      ? '${card.name.substring(0, 10)}...'
                      : card.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // [설명] 카드사 정보 (좌하단)
            Positioned(
              left: 20,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [설명] 카드사명 표시
                  Text(
                    card.company,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // [설명] 연회비 표시
                  Text(
                    '연회비: ${_formatWon(card.annualFee)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            // [설명] 카드 그라디언트 오버레이 (맨 위 카드 제외)
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
}

// [추가] 백엔드 추천 카드를 표시하는 위젯
// [설명] CreditCard 모델을 사용하여 카드 정보와 이미지를 표시
class _RecommendedCardFromBackend extends StatelessWidget {
  // [설명] 백엔드에서 받아온 카드 데이터
  final CreditCard card;

  const _RecommendedCardFromBackend({required this.card});

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
          // [중요] 백엔드에서 받아온 이미지 URL을 CardImageWidget으로 표시
          CardImageWidget(
            imageUrl: card.imageUrl,
            width: double.infinity,
            height: 80,
            borderRadius: 10,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 10),
          // [설명] 카드 이름 표시
          Text(
            card.name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              // [설명] 카드사 및 연회비 정보 표시
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.company,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '연회비: ${_formatWonStatic(card.annualFee)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // [추가] 정적 메서드로 금액 포맷팅 (StatelessWidget에서 사용)
  static String _formatWonStatic(int value) {
    final s = value.toString();
    final out = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    return '${out}원';
  }
}
