import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/perhitungan_model.dart';
import '../../models/user_model.dart';
import '../../services/chat_service.dart';
import '../../services/perhitungan_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';

class ChatPanel extends StatefulWidget {
  final VoidCallback? onClose;

  const ChatPanel({super.key, this.onClose});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _selectedTab = 0; // 0: Home/AI Hub, 1: Pesan, 2: Bantuan
  bool _isLoggedIn = false;
  bool _checkingLogin = true;
  bool _isSending = false;
  bool _loadingMetrics = false;

  UserModel? _currentUser;
  PerhitunganModel? _latestPerhitungan;

  final List<Map<String, String>> _messages = [];

  final List<Map<String, dynamic>> _quickPrompts = [
    {
      'icon': Icons.monitor_weight_outlined,
      'text': 'Cek status BMI & berat ideal',
    },
    {
      'icon': Icons.local_fire_department_outlined,
      'text': 'Hitung kebutuhan kalori harian',
    },
    {
      'icon': Icons.restaurant_menu_rounded,
      'text': 'Rekomendasi menu sarapan sehat',
    },
    {
      'icon': Icons.trending_down_rounded,
      'text': 'Tips defisit kalori tanpa lemas',
    },
    {
      'icon': Icons.directions_run_rounded,
      'text': 'Olahraga kardio ringan untuk pemula',
    },
    {
      'icon': Icons.eco_outlined,
      'text': 'Pilihan camilan sehat rendah gula',
    },
    {
      'icon': Icons.water_drop_outlined,
      'text': 'Berapa liter air harus diminum per hari?',
    },
  ];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'Bagaimana cara membaca status BMI?',
      'answer':
          'BMI dihitung dari berat badan (kg) dibagi kuadrat tinggi badan (m). '
          'Hasilnya mengelompokkan status menjadi Kurang, Normal, Berlebih, atau Obesitas.',
    },
    {
      'question': 'Apa bedanya BMR dan TDEE?',
      'answer':
          'BMR adalah kalori minimal yang dibakar saat istirahat total. '
          'TDEE adalah total kalori harian setelah memperhitungkan aktivitas fisik.',
    },
    {
      'question': 'Bagaimana cara menghitung kebutuhan kalori?',
      'answer':
          'Gunakan Kalkulator BMI & TDEE di FitLife. Masukkan tinggi, berat, usia, '
          'dan tingkat aktivitas untuk estimasi defisit atau surplus kalori.',
    },
    {
      'question': 'Berapa kebutuhan protein harian?',
      'answer':
          'Rata-rata 0.8–1.6 gram per kilogram berat badan tergantung intensitas olahraga Anda.',
    },
    {
      'question': 'Olahraga apa yang cocok untuk pemula?',
      'answer':
          'Mulai dengan jalan cepat 20-30 menit, peregangan ringan, atau bersepeda santai 3 kali seminggu.',
    },
    {
      'question': 'Bagaimana cara menggunakan Scan Makanan?',
      'answer':
          'Buka tab Scan, arahkan kamera ke barcode kemasan makanan, lalu FitLife akan menampilkan rincian nutrisinya.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userJson = prefs.getString('user');

    UserModel? user;
    if (userJson != null && userJson.isNotEmpty) {
      try {
        user = UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {}
    }

    if (!mounted) return;

    final isLoggedIn = token != null && token.isNotEmpty;

    // Langsung buka tampilan chatbot secara instan dengan profil lokal
    setState(() {
      _isLoggedIn = isLoggedIn;
      _currentUser = user;
      _checkingLogin = false;
      _loadingMetrics = isLoggedIn;
    });

    // Ambil data riwayat kalkulasi kesehatan dari server web di latar belakang
    if (isLoggedIn) {
      try {
        final history = await PerhitunganService().getHistory();
        if (history.isNotEmpty && mounted) {
          setState(() {
            _latestPerhitungan = history.first;
          });
        }
      } catch (_) {
      } finally {
        if (mounted) {
          setState(() {
            _loadingMetrics = false;
          });
        }
      }
    }
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
              'Silakan login terlebih dahulu untuk menggunakan asisten FitBot dan mendapatkan rekomendasi kesehatan personal.',
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
              (m) => <String, String>{
                'role': m['role']!,
                'content': m['content']!,
              },
            )
            .toList(),
      );

      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'assistant', 'content': answer});
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content':
              'Maaf, FitBot belum bisa merespons saat ini. Periksa koneksi internet atau coba beberapa saat lagi.',
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

  ThemeData get _theme => AppTheme.lightTheme;
  ColorScheme get _colorScheme => AppTheme.lightColorScheme;
  TextTheme get _textTheme => _theme.textTheme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _theme,
      child: Material(
        color: _colorScheme.surfaceContainer,
        elevation: 8,
        borderRadius: AppRadius.roundedLg,
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: _colorScheme.outlineVariant, width: 1.0),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildCurrentTab()),
              if (_selectedTab == 1 && _isLoggedIn) _buildMessageInput(),
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Header Panel ---
  Widget _buildHeader() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                padding: EdgeInsets.all(AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/maskot-ai/home-maskot.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.smart_toy_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: AppSpacing.sm - 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FitLife AI Hub',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  _isSending
                      ? 'Sedang mengetik...'
                      : 'Asisten kesehatan & nutrisi',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: _isSending
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight:
                        _isSending ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty && _selectedTab == 1)
            IconButton(
              tooltip: 'Mulai obrolan baru',
              iconSize: 18,
              onPressed: () {
                setState(() => _messages.clear());
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          if (widget.onClose != null)
            IconButton(
              tooltip: 'Tutup',
              iconSize: 20,
              onPressed: widget.onClose,
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    if (_checkingLogin) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isLoggedIn && _selectedTab != 2) {
      return _buildLoginRequiredView();
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

  // --- Login Required Banner (Sesuai Web) ---
  Widget _buildLoginRequiredView() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.roundedMd,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 28,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Login Diperlukan',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppSpacing.xxs + 2),
            Text(
              'Silakan login terlebih dahulu untuk menggunakan asisten FitBot dan mendapatkan rekomendasi kesehatan personal.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () {
                widget.onClose?.call();
                Navigator.pushNamed(context, '/login');
              },
              icon: const Icon(Icons.login_rounded, size: 16),
              label: const Text('Login Sekarang'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(160, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.roundedMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 0: Home / AI Hub (Sesuai Web) ---
  Widget _buildHomeTab() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    final userName = _currentUser?.name.isNotEmpty == true
        ? _currentUser!.name
        : (_currentUser?.username ?? 'Sobat FitLife');

    final lastMessage = _messages.isNotEmpty ? _messages.last : null;

    return ListView(
      padding: EdgeInsets.all(AppSpacing.sm),
      children: [
        // Greeting Banner
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, $userName! 👋',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                'Pusat layanan mandiri & asisten pintar kesehatan Anda.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Card 1: Percakapan Aktif
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: AppSpacing.xxs),
                      Text(
                        lastMessage != null
                            ? 'Lanjutkan Obrolan'
                            : 'Mulai Percakapan',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (lastMessage != null)
                    Text(
                      'Aktif',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                lastMessage != null
                    ? (lastMessage['role'] == 'assistant'
                        ? 'FitBot: ${lastMessage['content']}'
                        : 'Anda: ${lastMessage['content']}')
                    : 'Tanyakan seputar nutrisi, menu diet, atau panduan olahraga dengan FitBot AI.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => setState(() => _selectedTab = 1),
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: Text(
                        lastMessage != null ? 'Buka Obrolan' : 'Kirim Pesan',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedSm,
                        ),
                      ),
                    ),
                  ),
                  if (lastMessage != null) ...[
                    SizedBox(width: AppSpacing.xs),
                    IconButton.outlined(
                      tooltip: 'Mulai baru',
                      iconSize: 16,
                      onPressed: () {
                        setState(() {
                          _messages.clear();
                          _selectedTab = 1;
                        });
                      },
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.roundedSm,
                        ),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Card 2: Status Metrik Kesehatan (Sesuai Web)
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.favorite_outline_rounded,
                        size: 14,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Status Metrik Kesehatan',
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _loadingMetrics ? 'Sinkron...' : 'Terhubung',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: AppRadius.roundedSm,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status BMI',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latestPerhitungan != null
                                ? '${_latestPerhitungan!.bmi.toStringAsFixed(1)} • ${_latestPerhitungan!.status}'
                                : (_loadingMetrics
                                    ? 'Memuat data...'
                                    : 'Belum dihitung'),
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.xs + 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: AppRadius.roundedSm,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TB / BB',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _latestPerhitungan != null
                                ? '${_latestPerhitungan!.tinggiBadan.round()} cm / ${_latestPerhitungan!.beratBadan.round()} kg'
                                : (_currentUser?.height != null
                                    ? '${_currentUser!.height} cm / ${_currentUser!.weight} kg'
                                    : '- / -'),
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs + 2),
              InkWell(
                onTap: () {
                  _sendMessage(
                    'Jelaskan hasil status BMI terakhir saya dan berikan tips nutrisi yang sesuai.',
                  );
                },
                borderRadius: AppRadius.roundedSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 13,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Konsultasikan hasil ini dengan AI',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Card 3: Pintasan Cepat (Daftar Rapih Sesuai Web)
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainer,
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: AppSpacing.xxs),
                  Text(
                    'Pintasan Cepat',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              ...List.generate(_quickPrompts.length, (index) {
                final item = _quickPrompts[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Material(
                    color: colorScheme.surface,
                    borderRadius: AppRadius.roundedSm,
                    child: InkWell(
                      onTap: () => _sendMessage(item['text'] as String),
                      borderRadius: AppRadius.roundedSm,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.roundedSm,
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                            SizedBox(width: AppSpacing.xs + 2),
                            Expanded(
                              child: Text(
                                item['text'] as String,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // --- Tab 1: Pesan / Chat ---
  Widget _buildMessagesTab() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    final showWelcome = _messages.isEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(AppSpacing.sm),
            itemCount: showWelcome ? 1 : _messages.length,
            itemBuilder: (context, index) {
              if (showWelcome) {
                return const _ChatBubble(
                  isUser: false,
                  text:
                      'Halo! Saya FitBot, asisten kesehatan Anda. '
                      'Saya siap membantu pertanyaan seputar diet, nutrisi, olahraga, dan gaya hidup sehat. Ada yang bisa saya bantu? 😊',
                );
              }

              final msg = _messages[index];
              return _ChatBubble(
                isUser: msg['role'] == 'user',
                text: msg['content'] ?? '',
              );
            },
          ),
        ),
        if (_isSending)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'FitBot sedang mengetik...',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        // Pintasan chip cepat di atas input saat percakapan baru
        if (_messages.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: _quickPrompts.map((item) {
                  final text = item['text'] as String;
                  final icon = item['icon'] as IconData;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      avatar: Icon(icon, size: 14, color: colorScheme.primary),
                      label: Text(
                        text,
                        style: textTheme.labelSmall?.copyWith(fontSize: 11),
                      ),
                      backgroundColor:
                          colorScheme.primaryContainer.withValues(alpha: 0.5),
                      side: BorderSide(color: colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.roundedSm,
                      ),
                      onPressed: _isSending ? null : () => _sendMessage(text),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  // --- Input Box Chat ---
  Widget _buildMessageInput() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
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
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan ke FitBot...',
                    hintStyle: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.roundedMd,
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedMd,
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.roundedMd,
                      borderSide: BorderSide(
                        color: colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              IconButton.filled(
                onPressed: _isSending ? null : () => _sendMessage(),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.roundedMd,
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 4),
            child: Text(
              'FitBot adalah sarana edukasi. Konsultasikan dengan dokter untuk diagnosis medis.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 9.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Help / Bantuan FAQ ---
  Widget _buildHelpTab() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    return ListView(
      padding: EdgeInsets.all(AppSpacing.sm),
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: AppRadius.roundedLg,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pusat Bantuan FitBot',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Temukan jawaban untuk pertanyaan umum seputar kesehatan & fitur FitLife.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ..._faqs.map(
          (faq) => Card(
            margin: EdgeInsets.only(bottom: AppSpacing.xs),
            elevation: 0,
            color: colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd,
              side: BorderSide(color: colorScheme.outlineVariant),
            ),
            child: ExpansionTile(
              tilePadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              childrenPadding: EdgeInsets.fromLTRB(
                AppSpacing.sm,
                0,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              title: Text(
                faq['question']!,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    faq['answer']!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _sendMessage(faq['question']!),
                    icon: Icon(
                      Icons.chat_outlined,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      'Tanyakan ke FitBot',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Bottom Navigation Tab Bar (Sesuai Web) ---
  Widget _buildBottomNavigation() {
    final colorScheme = _colorScheme;
    final textTheme = _textTheme;

    final tabs = [
      {'label': 'Beranda', 'icon': Icons.home_rounded},
      {'label': 'Pesan', 'icon': Icons.chat_bubble_rounded},
      {'label': 'Bantuan', 'icon': Icons.help_outline_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;
          final item = tabs[index];

          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              borderRadius: AppRadius.roundedSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 20,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['label'] as String,
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
    final colorScheme = AppTheme.lightColorScheme;
    final textTheme = AppTheme.lightTheme.textTheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 270),
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.md),
            topRight: Radius.circular(AppRadius.md),
            bottomLeft: Radius.circular(isUser ? AppRadius.md : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadius.md),
          ),
          border: isUser ? null : Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          text,
          style: textTheme.bodySmall?.copyWith(
            color: isUser ? Colors.white : colorScheme.onSurface,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
