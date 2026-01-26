import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/config/theme.dart';

class ExpenseAnalysisPage extends StatefulWidget {
  const ExpenseAnalysisPage({super.key});

  @override
  State<ExpenseAnalysisPage> createState() => _ExpenseAnalysisPageState();
}

class _ExpenseAnalysisPageState extends State<ExpenseAnalysisPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 스크롤 제어를 위한 컨트롤러 (카테고리 클릭 시 차트로 자동 스크롤)
  final ScrollController _scrollController = ScrollController();
  
  // 차트 위젯의 위치를 식별하기 위한 키
  final GlobalKey _chartKey = GlobalKey();
  
  String? _selectedCategory;

  // 더미 데이터
  final Map<String, Map<String, int>> categoryDetails = {
    '식비': {
      '배달': 180000,
      '외식': 220000,
      '카페': 75000,
      '편의점': 45000,
    },
    '교통': {
      '대중교통': 85000,
      '택시': 45000,
      '주유': 50000,
    },
    '쇼핑': {
      '의류': 200000,
      '쿠팡': 150000,
      '기타 온라인': 100000,
    },
    '생활': {
      '통신비': 80000,
      '공과금': 120000,
      '마트': 120000,
    },
    '기타': {
      '문화생활': 150000,
      '의료비': 80000,
      '기타': 150000,
    },
  };

  final List<Map<String, dynamic>> recentExpenses = [
    {'merchant': '스타벅스', 'category': '식비', 'amount': 5500, 'date': '01.20'},
    {'merchant': '쿠팡', 'category': '쇼핑', 'amount': 35000, 'date': '01.19'},
    {'merchant': '카카오택시', 'category': '교통', 'amount': 12000, 'date': '01.19'},
    {'merchant': '배달의민족', 'category': '식비', 'amount': 25000, 'date': '01.18'},
    {'merchant': 'GS25', 'category': '식비', 'amount': 4500, 'date': '01.18'},
    {'merchant': '네이버페이', 'category': '쇼핑', 'amount': 89000, 'date': '01.17'},
    {'merchant': '지하철', 'category': '교통', 'amount': 1500, 'date': '01.17'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose(); // 스크롤 컨트롤러 메모리 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지출 분석'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '카테고리별'),
            Tab(text: '최근 내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryTab(),
          _buildRecentTab(),
        ],
      ),
    );
  }

  Widget _buildCategoryTab() {
    return SingleChildScrollView(
      controller: _scrollController, // 스크롤 제어를 위해 컨트롤러 연결
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 대분류 도넛 차트
          _buildMainCategoryChart(),

          const SizedBox(height: 16),

          // 선택된 카테고리 중분류
          if (_selectedCategory != null) _buildSubCategoryCard(),

          const SizedBox(height: 16),

          // 카테고리 목록
          _buildCategoryList(),
        ],
      ),
    );
  }

  Widget _buildMainCategoryChart() {
    final total = categoryDetails.values
        .expand((v) => v.values)
        .reduce((a, b) => a + b);
    final colors = AppColors.chartColors;

    return Container(
      key: _chartKey, // 스크롤 목표 지점을 식별하기 위한 키
      child: Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '이번 달 카테고리별 지출',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '총 ${_formatCurrency(total)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (response?.touchedSection != null) {
                        final index =
                            response!.touchedSection!.touchedSectionIndex;
                        if (index >= 0) {
                          setState(() {
                            _selectedCategory =
                                categoryDetails.keys.toList()[index];
                          });
                        }
                      }
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: categoryDetails.entries.map((entry) {
                    final index =
                        categoryDetails.keys.toList().indexOf(entry.key);
                    final categoryTotal =
                        entry.value.values.reduce((a, b) => a + b);
                    final percentage = (categoryTotal / total * 100);
                    final isSelected = _selectedCategory == entry.key;

                    return PieChartSectionData(
                      color: colors[index % colors.length],
                      value: categoryTotal.toDouble(),
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: isSelected ? 60 : 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSubCategoryCard() {
    final subCategories = categoryDetails[_selectedCategory]!;
    final categoryTotal = subCategories.values.reduce((a, b) => a + b);
    final categoryIndex = categoryDetails.keys.toList().indexOf(_selectedCategory!);
    final color = AppColors.chartColors[categoryIndex % AppColors.chartColors.length];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_selectedCategory 상세',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCurrency(categoryTotal),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...subCategories.entries.map((entry) {
              final percentage = entry.value / categoryTotal;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text(
                          _formatCurrency(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppColors.textLight.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation(color.withOpacity(0.7)),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    final colors = AppColors.chartColors;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '카테고리 목록',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...categoryDetails.entries.map((entry) {
              final index = categoryDetails.keys.toList().indexOf(entry.key);
              final total = entry.value.values.reduce((a, b) => a + b);
              final isSelected = _selectedCategory == entry.key;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory =
                        _selectedCategory == entry.key ? null : entry.key;
                  });
                  // setState 이후 화면이 다시 그려진 후 스크롤 실행
                  // 바로 실행하면 setState 렌더링과 충돌할 수 있음
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToChart(); // 차트 위치로 자동 스크롤
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors[index % colors.length].withOpacity(0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getCategoryIcon(entry.key),
                          color: colors[index % colors.length],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${entry.value.length}개 항목',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isSelected
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_right,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recentExpenses.length,
      itemBuilder: (context, index) {
        final expense = recentExpenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getCategoryIcon(expense['category']),
                color: AppColors.primary,
              ),
            ),
            title: Text(
              expense['merchant'],
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${expense['category']} | ${expense['date']}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: Text(
              '-${_formatCurrency(expense['amount'])}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        );
      },
    );
  }

  // 카테고리 클릭 시 차트 위치로 스크롤하는 메서드
  void _scrollToChart() {
    // 방법 1: 스크롤을 맨 위(0)로 부드럽게 이동
    _scrollController.animateTo(
      0, // 스크롤 목표 위치 (0 = 최상단)
      duration: const Duration(milliseconds: 350), // 애니메이션 시간
      curve: Curves.easeInOut, // 부드러운 애니메이션 곡선
    );
    
    // 방법 2: ensureVisible 사용 (백업 - 필요 시 주석 해제)
    // _chartKey로 식별된 위젯이 화면에 보이도록 스크롤
    // final ctx = _chartKey.currentContext;
    // if (ctx != null) {
    //   Scrollable.ensureVisible(
    //     ctx,
    //     duration: const Duration(milliseconds: 350),
    //     curve: Curves.easeInOut,
    //   );
    // }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '식비':
        return Icons.restaurant;
      case '교통':
        return Icons.directions_car;
      case '쇼핑':
        return Icons.shopping_bag;
      case '생활':
        return Icons.home;
      default:
        return Icons.more_horiz;
    }
  }

  String _formatCurrency(int amount) {
    if (amount >= 10000) {
      final man = amount ~/ 10000;
      final remainder = amount % 10000;
      if (remainder == 0) {
        return '${man}만원';
      }
      return '${man}만 ${remainder}원';
    }
    return '${amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        )}원';
  }
}
