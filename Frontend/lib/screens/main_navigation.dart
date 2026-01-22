import 'package:flutter/material.dart';
import 'package:my_app/screens/home/home_page.dart';
import 'package:my_app/screens/cards/card_analysis_page.dart';
import 'package:my_app/screens/subscription/subscription_page.dart';
import 'package:my_app/screens/chat/chat_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _Conversation {
  final int id;
  final String title;
  final String lastMessage;
  final String time;

  const _Conversation({required this.id, required this.title, required this.lastMessage, required this.time});
}

class ChatbotFloating extends StatelessWidget {
  final VoidCallback? onTap;

  const ChatbotFloating({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1560FF),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.14), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.question_mark, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class ChatbotSheet extends StatefulWidget {
  const ChatbotSheet({super.key});

  @override
  State<ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<ChatbotSheet> {
  int _selectedIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<_Conversation> _allConversations = const [
    _Conversation(id: 1, title: '카드 추천 문의', lastMessage: '토스카드 추천 감사합니다!', time: '1일 전'),
    _Conversation(id: 2, title: '구독 해지 문의', lastMessage: '넷플릭스 구독 해지 방법 알려주세요', time: '3일 전'),
    _Conversation(id: 3, title: '카페 지출 문의', lastMessage: '이번달 카페 지출이 많은 것 같아요', time: '1주 전'),
  ];

  List<_Conversation> get _filteredConversations {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return _allConversations;
    return _allConversations.where((c) => c.title.contains(q) || c.lastMessage.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.86;

    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).viewInsets.top),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header: avatar, title, close
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.circle, color: Colors.blue, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('베네핏(BeneFit)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              // Content area: separate Home and Conversation screens using IndexedStack
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: [
                    // Home screen
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message card
                          Container(
                            decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('안녕하세요! BeneFit(베네핏)입니다 :)', style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 8),
                                const Text('궁금한 점이 있다면 언제든 편하게 말씀해 주세요! 💬', style: TextStyle(fontSize: 13, color: Colors.black87)),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1560FF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text('문의하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                        SizedBox(width: 8),
                                        Icon(Icons.send, color: Colors.white, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('챗봇 이용중', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 12),
                          // Home can have additional content below
                          const SizedBox(height: 200),
                        ],
                      ),
                    ),

                    // Conversation screen
                    Column(
                      children: [
                        // 검색창
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: '채팅 검색',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: const Color(0xFFF4F6F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredConversations.length,
                            itemBuilder: (context, idx) {
                              final c = _filteredConversations[idx];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF6F7F8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        CircleAvatar(radius: 20, backgroundColor: Colors.white, child: Icon(Icons.smart_toy, color: Colors.blue)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                              const SizedBox(height: 6),
                                              Text(c.lastMessage, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                            ],
                                          ),
                                        ),
                                        Text(c.time, style: const TextStyle(color: Colors.black45, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // 새 문의하기 버튼
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 6),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChatPage()));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1560FF),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('새 문의하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                  SizedBox(width: 8),
                                  Icon(Icons.send, color: Colors.white, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Bottom tab bar inside sheet (홈, 대화)
              SizedBox(
                height: 68,
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedIndex = 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home, color: _selectedIndex == 0 ? const Color(0xFF1560FF) : Colors.grey, size: 22),
                            const SizedBox(height: 6),
                            Text('홈', style: TextStyle(color: _selectedIndex == 0 ? const Color(0xFF1560FF) : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                          onTap: () => setState(() => _selectedIndex = 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble, color: _selectedIndex == 1 ? const Color(0xFF1560FF) : Colors.grey, size: 22),
                            const SizedBox(height: 6),
                            Text('대화', style: TextStyle(color: _selectedIndex == 1 ? const Color(0xFF1560FF) : Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CardAnalysisPage(),
    const SubscriptionPage(),
  ];

  Widget _buildNavItem({required int index, required IconData icon, required String label}) {
    final bool selected = _currentIndex == index;
    final color = selected ? const Color(0xFF0066FF) : Colors.grey.shade500;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          // Floating chatbot widget visible across all main pages
          Positioned(
            right: 16,
            bottom: 110, // sits above the bottom navigation bar
            child: ChatbotFloating(onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ChatbotSheet(),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            _buildNavItem(index: 0, icon: Icons.home, label: '홈'),
            _buildNavItem(index: 1, icon: Icons.credit_card, label: '카드'),
            _buildNavItem(index: 2, icon: Icons.subscriptions, label: '구독'),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
