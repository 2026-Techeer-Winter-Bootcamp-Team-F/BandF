import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_app/config/theme.dart';
import 'package:my_app/screens/analysis/category_detail_page.dart';
import 'package:my_app/services/transaction_service.dart';
import 'package:my_app/models/home_data.dart' as models;
import 'package:my_app/screens/bank/bank_selection_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  // 카드 스택 위젯

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // API 서비스
  final TransactionService _transactionService = TransactionService();

  // 로딩 상태
  bool isLoading = false;
  String? errorMessage;

  // 현재 선택된 월
  DateTime selectedMonth = DateTime.now();
  DateTime? selectedDate; //For daily view selection

  // API Models
  models.AccumulatedData? accumulatedData;
  models.DailySummary? dailySummary;
  models.WeeklyData? weeklyData;
  models.MonthlyData? monthlyData;
  List<models.CategoryData>? categories;
  models.MonthComparison? monthComparison;
  Map<int, List<models.Transaction>> dailyTransactionsCache = {};

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final year = selectedMonth.year;
      final month = selectedMonth.month;

      final results = await Future.wait([
        _transactionService.getAccumulatedData(year, month),
        _transactionService.getDailySummary(year, month),
        _transactionService.getWeeklyAverage(year, month),
        _transactionService.getMonthlyAverage(year, month),
        _transactionService.getCategorySummary(year, month),
        _transactionService.getMonthComparison(year, month),
      ]);

      setState(() {
        accumulatedData = results[0] as models.AccumulatedData;
        dailySummary = results[1] as models.DailySummary;
        weeklyData = results[2] as models.WeeklyData;
        monthlyData = results[3] as models.MonthlyData;
        categories = results[4] as List<models.CategoryData>;
        monthComparison = results[5] as models.MonthComparison;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = '데이터를 불러오는데 실패했습니다: $e';
        isLoading = false;
      });
    }
  }

  // 상단 스크롤 페이지 인덱스 (누적/주간/월간)
  int topPageIndex = 0;
  final PageController topPageController = PageController();

  // 하단 스크롤 페이지 인덱스 (카테고리/지난달 비교)
  int bottomPageIndex = 0;
  final PageController bottomPageController = PageController();

  // 도넛 차트 선택된 카테고리 인덱스
  int selectedCategoryIndex = 0;

  // 데이터 접근 헬퍼 메서드들
  int get thisMonthTotal => accumulatedData?.total ?? 0;
  int get lastMonthSameDay => monthComparison?.lastMonthSameDay ?? 0;
  int get weeklyAverage => weeklyData?.average ?? 0;
  int get monthlyAverage => monthlyData?.average ?? 0;

  Map<String, Map<String, dynamic>> get categoryData {
    if (categories == null) return {};

    final Map<String, Map<String, dynamic>> result = {};
    for (var category in categories!) {
      result[category.name] = {
        'amount': category.amount,
        'change': category.change,
        'percent': category.percent,
        'icon': category.emoji,
        'color': category.color,
      };
    }
    return result;
  }

  List<double> get thisMonthDailyData {
    return accumulatedData?.dailyData.map((e) => e.amount).toList() ?? [];
  }

  List<double> get lastMonthDailyData {
    return monthComparison?.lastMonthData.map((e) => e.amount).toList() ?? [];
  }

  @override
  void dispose() {
    topPageController.dispose();
    bottomPageController.dispose();
    super.dispose();
  }

  // (카드 스택은 홈 탭으로 이동됨)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 월 선택 헤더
            _buildMonthHeader(),

            // 스크롤 가능한 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    const SizedBox(height: 16),

                    // 상단 섹션 (누적/주간/월간)
                    _buildTopSection(),

                    const SizedBox(height: 32),

                    // 이번달/지난달 비교 탭
                    _buildTabButtons(),

                    const SizedBox(height: 16),

                    // 하단 섹션 (카테고리/지난달 비교)
                    _buildBottomSection(),

                    const SizedBox(height: 80), // 하단 네비게이션 바 공간
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 상단 월 선택 헤더
  Widget _buildMonthHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final newDate = DateTime(
                selectedMonth.year,
                selectedMonth.month - 1,
              );
              _onMonthChanged(newDate);
            },
          ),
          Text(
            '${selectedMonth.month}월',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final newDate = DateTime(
                selectedMonth.year,
                selectedMonth.month + 1,
              );
              _onMonthChanged(newDate);
            },
          ),
        ],
      ),
    );
  }

  void _onMonthChanged(DateTime newDate) {
    setState(() {
      selectedMonth = newDate;
      selectedDate = null;
    });
    _loadHomeData();
  }

  // 상단 섹션 (누적/주간/월간 스크롤)
  Widget _buildTopSection() {
    return Column(
      children: [
        // 페이지 인디케이터
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIndicator('누적', 0),
            const SizedBox(width: 24),
            _buildIndicator('주간', 1),
            const SizedBox(width: 24),
            _buildIndicator('월간', 2),
          ],
        ),
        const SizedBox(height: 16),

        // 스크롤 가능한 페이지
        SizedBox(
          height: 320,
          child: PageView(
            controller: topPageController,
            onPageChanged: (index) {
              setState(() {
                topPageIndex = index;
              });
            },
            children: [
              _buildAccumulatedView(),
              _buildWeeklyView(),
              _buildMonthlyView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(String label, int index) {
    final isSelected = topPageIndex == index;
    return GestureDetector(
      onTap: () {
        topPageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }

  // 누적 소비 금액 뷰
  Widget _buildAccumulatedView() {
    final difference = lastMonthSameDay - thisMonthTotal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 차트 영역
          Container(
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomPaint(
              size: const Size(double.infinity, 150),
              painter: LineChartPainter(
                thisMonthData: thisMonthDailyData,
                lastMonthData: lastMonthDailyData,
                currentDay: 19, // 1월 19일까지 데이터
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 텍스트 정보
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '지난달 같은 기간보다\n'),
                TextSpan(
                  text: _formatCurrency(difference),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 덜 썼어요'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 월별 데이터
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMonthData('1월 19일까지', thisMonthTotal, Colors.green),
              const SizedBox(width: 40),
              _buildMonthData('12월 19일까지', lastMonthSameDay, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthData(String label, int amount, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrencyFull(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // 주간 평균 뷰
  Widget _buildWeeklyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 차트 영역 (데이터가 없으므로 임시 숨김 처리 하거나 텍스트 내용만 표시)
          Container(
            height: 100, // 높이 축소
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "주간 차트 데이터 준비 중입니다.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 텍스트 정보
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '일주일 평균\n'),
                TextSpan(
                  text: _formatCurrency(weeklyAverage),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 정도 썼어요'),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBarChart(
    String label,
    int amount,
    int maxAmount, {
    bool isToday = false,
  }) {
    final height = amount > 0 ? (amount / maxAmount * 120) : 2;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${(amount / 10000).toStringAsFixed(0)}만',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        Container(
          width: 40,
          height: height.toDouble(),
          decoration: BoxDecoration(
            color: isToday ? const Color(0xFF4CAF50) : const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // 월간 평균 뷰
  Widget _buildMonthlyView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 차트 영역
          Container(
            height: 100, // 높이 축소
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                "월간 차트 데이터 준비 중입니다.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 텍스트 정보
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '월 평균\n'),
                TextSpan(
                  text: _formatCurrency(monthlyAverage),
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' 정도 썼어요'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMonthlyBar(
    String label,
    int amount,
    int maxAmount, {
    bool isCurrentMonth = false,
  }) {
    final height = (amount / maxAmount * 120);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (amount > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${(amount / 10000).toStringAsFixed(0)}만',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ),
        Container(
          width: 40,
          height: height,
          decoration: BoxDecoration(
            color: isCurrentMonth
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  // 이번달/지난달 비교 탭 버튼
  Widget _buildTabButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                bottomPageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: bottomPageIndex == 0
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '이번달',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bottomPageIndex == 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: bottomPageIndex == 0 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                bottomPageController.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: bottomPageIndex == 1
                          ? Colors.black
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '지난달 비교',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bottomPageIndex == 1
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: bottomPageIndex == 1 ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 하단 섹션 (카테고리/지난달 비교)
  Widget _buildBottomSection() {
    return SizedBox(
      height: 700,
      child: PageView(
        controller: bottomPageController,
        onPageChanged: (index) {
          setState(() {
            bottomPageIndex = index;
          });
        },
        children: [
          SingleChildScrollView(child: _buildCategoryView()),
          SingleChildScrollView(child: _buildComparisonView()),
        ],
      ),
    );
  }

  // 소비 카테고리 뷰
  Widget _buildCategoryView() {
    if (categoryData.isEmpty) {
      return SizedBox(
        height: 300,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '지출 내역이 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BankSelectionPage(name: 'User'),
                  ),
                );
              },
              child: const Text('카드 연결하기'),
            ),
          ],
        ),
      );
    }

    if (selectedCategoryIndex >= categoryData.length) {
      selectedCategoryIndex = 0;
    }

    final selectedEntry = categoryData.entries.toList()[selectedCategoryIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 메시지
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: selectedEntry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '에\n가장 많이 썼어요'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 도넛 차트
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (event is FlTapUpEvent &&
                            pieTouchResponse != null &&
                            pieTouchResponse.touchedSection != null) {
                          setState(() {
                            final touchedIndex = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                            if (touchedIndex >= 0 &&
                                touchedIndex < categoryData.length) {
                              selectedCategoryIndex = touchedIndex;
                            }
                          });
                        }
                      },
                    ),
                    sections: categoryData.entries.toList().asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final data = entry.value.value;
                        final isSelected = index == selectedCategoryIndex;

                        return PieChartSectionData(
                          color: data['color'] as Color,
                          value: (data['percent'] as int).toDouble(),
                          title: '',
                          radius: isSelected ? 35 : 30,
                        );
                      },
                    ).toList(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectedEntry.value['icon'] as String,
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedEntry.value['percent']}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        selectedEntry.key,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 카테고리 목록
          ...categoryData.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value;
            return _buildCategoryItem(
              data.value['icon'] as String,
              data.key,
              data.value['percent'] as int,
              data.value['amount'] as int,
              data.value['change'] as int,
              data.value['color'] as Color,
              isSelected: index == selectedCategoryIndex,
              onTap: () {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
            );
          }),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoryDetailPage(),
                ),
              );
            },
            child: const Text('더보기 >'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    String icon,
    String name,
    int percent,
    int amount,
    int change,
    Color color, {
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    final isPositive = change > 0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$percent%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatCurrencyFull(amount),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${_formatCurrencyFull(change)}',
              style: TextStyle(
                fontSize: 12,
                color: isPositive
                    ? const Color(0xFFFF5252)
                    : const Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 지난달 비교 뷰
  Widget _buildComparisonView() {
    final topCategory = categoryData.entries.first;
    final topChange = (topCategory.value['change'] as int).abs();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 메시지
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: '지난달 이맘때 대비\n'),
                TextSpan(
                  text: topCategory.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' 지출이 줄었어요'),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 카테고리별 막대 그래프
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categoryData.entries.map((entry) {
                final percent = entry.value['percent'] as int;
                final change = entry.value['change'] as int;
                final lastMonthPercent = percent + (change / 10000).round();

                return _buildComparisonBar(
                  entry.key,
                  lastMonthPercent,
                  percent,
                  entry.value['color'] as Color,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // 상세 정보
          Column(
            children: [
              _buildComparisonDetail(
                '1월 19일까지',
                '49%',
                _formatCurrencyFull(317918),
              ),
              const SizedBox(height: 8),
              _buildComparisonDetail(
                '12월 19일까지',
                '55%',
                _formatCurrencyFull(553230),
              ),
              const SizedBox(height: 8),
              _buildComparisonDetail(
                '증감',
                '-6%',
                _formatCurrencyFull(-235312),
                isChange: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(
    String label,
    int lastMonth,
    int thisMonth,
    Color color,
  ) {
    final maxHeight = 150.0;
    final lastMonthHeight = (lastMonth / 60 * maxHeight).clamp(10.0, maxHeight);
    final thisMonthHeight = (thisMonth / 60 * maxHeight).clamp(10.0, maxHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 16,
              height: lastMonthHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 16,
              height: thisMonthHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 40,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonDetail(
    String label,
    String percent,
    String amount, {
    bool isChange = false,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isChange
                ? Colors.transparent
                : (label.contains('1월') ? Colors.green : Colors.grey),
            shape: BoxShape.circle,
            border: isChange ? Border.all(color: Colors.grey, width: 1) : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        Text(
          percent,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 100,
          child: Text(
            amount,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isChange && amount.startsWith('-')
                  ? const Color(0xFF4CAF50)
                  : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    if (amount.abs() >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},')}원';
  }

  String _formatCurrencyFull(int amount) {
    final formatted = amount.abs().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return '${amount < 0 ? '-' : ''}${formatted}원';
  }
}

// 간단한 라인 차트 페인터
class LineChartPainter extends CustomPainter {
  final List<double> thisMonthData;
  final List<double> lastMonthData;
  final int currentDay;

  LineChartPainter({
    required this.thisMonthData,
    required this.lastMonthData,
    required this.currentDay,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (lastMonthData.isEmpty && thisMonthData.isEmpty) return;

    // 최대값 계산 (스케일링을 위해)
    double maxValue = 100000.0; // 기본값
    if (lastMonthData.isNotEmpty) {
      maxValue = lastMonthData.reduce((a, b) => a > b ? a : b);
    }
    if (thisMonthData.isNotEmpty) {
      final thisMax = thisMonthData.reduce((a, b) => a > b ? a : b);
      if (thisMax > maxValue) maxValue = thisMax;
    }
    if (maxValue == 0) maxValue = 1.0;

    final padding = 10.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    // 지난달 그래프 그리기 (회색, 전체 기간)
    if (lastMonthData.isNotEmpty) {
      _drawMonthLine(
        canvas,
        lastMonthData,
        maxValue,
        chartWidth,
        chartHeight,
        padding,
        Colors.grey.withOpacity(0.3),
        Colors.grey.withOpacity(0.05),
        lastMonthData.length,
      );
    }

    // 이번달 그래프 그리기 (초록색, 현재 날짜까지만)
    if (thisMonthData.isNotEmpty) {
      _drawMonthLine(
        canvas,
        thisMonthData,
        maxValue,
        chartWidth,
        chartHeight,
        padding,
        const Color(0xFF4CAF50),
        const Color(0xFF4CAF50).withOpacity(0.1),
        currentDay,
      );
    }

    // 날짜 레이블 그리기
    _drawLabels(canvas, size, chartWidth, padding);
  }

  void _drawMonthLine(
    Canvas canvas,
    List<double> data,
    double maxValue,
    double chartWidth,
    double chartHeight,
    double padding,
    Color lineColor,
    Color fillColor,
    int dataLength,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    // 데이터 포인트 계산
    final pointsToUse = data.take(dataLength).toList();
    if (pointsToUse.isEmpty) return;

    // x축 간격 계산 (최대 31일 기준)
    final xStep = chartWidth / 31;

    // 첫 번째 포인트
    final firstX = padding;
    final firstY =
        padding + chartHeight - (pointsToUse[0] / maxValue * chartHeight);

    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, padding + chartHeight);
    fillPath.lineTo(firstX, firstY);

    // 나머지 포인트들 - 부드러운 곡선으로 연결
    for (int i = 1; i < pointsToUse.length; i++) {
      final x = padding + (i * xStep);
      final y =
          padding + chartHeight - (pointsToUse[i] / maxValue * chartHeight);

      if (i == 1) {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        // 베지어 곡선으로 부드럽게 연결
        final prevX = padding + ((i - 1) * xStep);
        final prevY =
            padding +
            chartHeight -
            (pointsToUse[i - 1] / maxValue * chartHeight);

        final controlX = (prevX + x) / 2;

        path.quadraticBezierTo(controlX, prevY, x, y);
        fillPath.quadraticBezierTo(controlX, prevY, x, y);
      }
    }

    // Fill path 완성
    final lastX = padding + ((pointsToUse.length - 1) * xStep);
    fillPath.lineTo(lastX, padding + chartHeight);
    fillPath.close();

    // 그리기
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // 마지막 점 표시 (이번달 데이터인 경우에만)
    if (lineColor == const Color(0xFF4CAF50)) {
      final lastPointX = padding + ((pointsToUse.length - 1) * xStep);
      final lastPointY =
          padding + chartHeight - (pointsToUse.last / maxValue * chartHeight);

      final circlePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(lastPointX, lastPointY), 5, borderPaint);
      canvas.drawCircle(Offset(lastPointX, lastPointY), 3.5, circlePaint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Size size,
    double chartWidth,
    double padding,
  ) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final labelStyle = TextStyle(color: Colors.grey[600], fontSize: 10);

    // 날짜 레이블 (1일, 중간, 31일)
    final labels = [
      {'text': '1.1', 'position': 0.0},
      {'text': '1.19', 'position': 18 / 31}, // 현재 날짜
      {'text': '1.31', 'position': 1.0},
    ];

    for (final label in labels) {
      textPainter.text = TextSpan(
        text: label['text'] as String,
        style: labelStyle,
      );
      textPainter.layout();

      final x =
          padding +
          (chartWidth * (label['position'] as double)) -
          textPainter.width / 2;
      final y = size.height - 8;

      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.thisMonthData != thisMonthData ||
        oldDelegate.lastMonthData != lastMonthData ||
        oldDelegate.currentDay != currentDay;
  }
}
