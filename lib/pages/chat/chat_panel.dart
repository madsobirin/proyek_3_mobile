import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/services/chat_service.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  static const Color green = Color(0xFF247447);
  static const Color lightGreen = Color(0xFFEAF5EE);

  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedTab = 0;
  bool _isLoggedIn = false;
  bool _checkingLogin = true;
  bool _isSending = false;

  final List<Map<String, String>> _messages = [];

  final List<String> _quickPrompts = [
    'Cek tinggi & berat badan',
    'Status BMI terakhir',
    'Hitung kalori harian',
    'Rekomendasi menu diet',
  ];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Bagaimana cara membaca status BMI?',
      'answer':
          'BMI dihitung dari berat badan (kg) dibagi tinggi badan (m) kuadrat. '
          'Hasilnya membantu memberikan gambaran kategori berat badan, '
          'tetapi bukan satu-satunya penilaian kesehatan.',
    },
    {
      'question': 'Apa bedanya BMR dan TDEE?',
      'answer':
          'BMR adalah perkiraan energi yang dibutuhkan tubuh saat istirahat. '
          'TDEE memperkirakan kebutuhan energi total setelah aktivitas harian '
          'ikut diperhitungkan.',
    },
    {
      'question': 'Bagaimana cara menghitung kebutuhan kalori?',
      'answer':
          'Kebutuhan energi dipengaruhi oleh usia, ukuran tubuh, aktivitas, '
          'dan kondisi individu. Gunakan hasil perhitungan sebagai perkiraan, '
          'bukan angka mutlak.',
    },
    {
      'question': 'Berapa kebutuhan protein harian?',
      'answer':
          'Kebutuhan protein berbeda-beda sesuai usia, aktivitas, dan kondisi '
          'kesehatan. Usahakan memperoleh protein dari makanan yang beragam.',
    },
    {
      'question': 'Olahraga apa yang cocok untuk pemula?',
      'answer':
          'Kamu bisa memulai dengan berjalan kaki, bersepeda santai, atau '
          'aktivitas ringan yang terasa nyaman. Tingkatkan aktivitas secara '
          'bertahap sesuai kemampuan.',
    },
    {
      'question': 'Bagaimana cara menggunakan Scan Makanan?',
      'answer':
          'Buka fitur Scan Makanan, arahkan kamera ke barcode produk, lalu '
          'periksa informasi nutrisi yang berhasil ditemukan. Data produk '
          'mungkin tidak tersedia untuk semua barcode.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (!mounted) return;

    setState(() {
      _isLoggedIn = token != null && token.isNotEmpty;
      _checkingLogin = false;
    });
  }

  Future<void> _sendMessage([String? prompt]) async {
    final text = (prompt ?? _messageController.text).trim();

    if (text.isEmpty || _isSending) return;

    _messageController.clear();

    setState(() {
      _selectedTab = 1;
      _messages.add({'role': 'user', 'content': text});
    });

    _scrollToBottom();

    if (!_isLoggedIn) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Silakan login ke akun FitLife terlebih dahulu agar bisa '
              'menggunakan percakapan FitBot.',
        });
      });
      _scrollToBottom();
      return;
    }

    setState(() => _isSending = true);

    try {
      final answer = await _chatService.sendMessage(
        _messages
            .map(
              (message) => <String, String>{
                'role': message['role']!,
                'content': message['content']!,
              },
            )
            .toList(),
      );

      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'assistant', 'content': answer});
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Maaf, FitBot belum bisa menjawab saat ini. '
              'Periksa koneksi internet dan status login kamu, lalu coba lagi.',
        });
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 12,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildCurrentTab()),
          if (_selectedTab == 1) _buildMessageInput(),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: green,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/maskot-ai/home-maskot.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.smart_toy_rounded, color: green, size: 30),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FitBot',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Asisten kesehatan FitLife',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Mulai percakapan baru',
            onPressed: () {
              setState(() {
                _messages.clear();
                _selectedTab = 1;
              });
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_checkingLogin) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedTab) {
      case 1:
        return _buildMessagesTab();
      case 2:
        return _buildHelpTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Halo! 👋',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ada yang ingin kamu tanyakan tentang pola hidup sehat?',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/maskot-ai/home-maskot.png',
              width: 75,
              height: 75,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.smart_toy_rounded, size: 65, color: green),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mulai percakapan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tanyakan hal seputar nutrisi, olahraga, dan kebiasaan sehat.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _selectedTab = 1);
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Chat dengan FitBot'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Pertanyaan yang sering ditanyakan',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 9),
        ..._quickPrompts.map(
          (prompt) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _sendMessage(prompt),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: green,
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(prompt, style: const TextStyle(fontSize: 12)),
                    ),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Jelajahi FitLife',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _FeatureChip(label: 'Kalkulator BMI'),
            _FeatureChip(label: 'Menu Sehat'),
            _FeatureChip(label: 'Scan Makanan'),
            _FeatureChip(label: 'Lokasi Olahraga'),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesTab() {
    final showWelcome = _messages.isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: showWelcome ? 1 : _messages.length,
            itemBuilder: (context, index) {
              if (showWelcome) {
                return const _ChatBubble(
                  isUser: false,
                  text:
                      'Halo! Saya FitBot, asisten kesehatan kamu. '
                      'Aku siap membantu pertanyaan seputar nutrisi, '
                      'olahraga, dan gaya hidup sehat. 😊',
                );
              }

              final message = _messages[index];
              return _ChatBubble(
                isUser: message['role'] == 'user',
                text: message['content'] ?? '',
              );
            },
          ),
        ),
        if (_isSending)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  'FitBot sedang mengetik...',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        if (_messages.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickPrompts.take(3).map((prompt) {
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 10)),
                  onPressed: _isSending ? null : () => _sendMessage(prompt),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: const TextStyle(fontSize: 12),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              IconButton.filled(
                onPressed: _isSending ? null : () => _sendMessage(),
                style: IconButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 19),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 5, bottom: 3),
            child: Text(
              'FitBot memberikan informasi edukasi, bukan diagnosis medis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text(
          'Pusat Bantuan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          'Temukan jawaban untuk pertanyaan umum tentang FitLife.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        const SizedBox(height: 12),
        ..._faqs.map(
          (faq) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            color: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              title: Text(
                faq['question']!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq['answer']!,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _sendMessage(faq['question']!),
                    icon: const Icon(Icons.chat_outlined, size: 16),
                    label: const Text('Tanyakan ke FitBot'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    const labels = ['Home', 'Messages', 'Help'];
    const icons = [
      Icons.home_rounded,
      Icons.chat_bubble_rounded,
      Icons.help_outline_rounded,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = _selectedTab == index;

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[index],
                    size: 20,
                    color: selected ? green : Colors.grey,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selected ? green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final bool isUser;
  final String text;

  const _ChatBubble({required this.isUser, required this.text});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF247447);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 270),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? green : const Color(0xFFF0F3F1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;

  const _FeatureChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      avatar: const Icon(
        Icons.eco_outlined,
        color: Color(0xFF247447),
        size: 16,
      ),
      backgroundColor: const Color(0xFFEAF5EE),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
