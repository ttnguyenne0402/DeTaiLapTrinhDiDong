import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../services/ai_chat_service.dart';

class AiChatbotScreen extends StatefulWidget {
  final String initialRole; // 'tenant', 'owner', 'admin'
  const AiChatbotScreen({super.key, this.initialRole = 'tenant'});

  @override
  State<AiChatbotScreen> createState() => _AiChatbotScreenState();
}

class _AiChatbotScreenState extends State<AiChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  late String _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.initialRole;
    _loadChatSession();
  }

  Future<void> _loadChatSession() async {
    final savedMessages = await AiChatService.loadChatHistory(_currentRole);
    if (!mounted) return;
    setState(() {
      _messages.clear();
      if (savedMessages.isNotEmpty) {
        _messages.addAll(savedMessages);
      } else {
        _initWelcomeMessage();
      }
    });
    _scrollToBottom();
  }

  void _initWelcomeMessage() {
    String greeting;
    if (_currentRole == 'owner') {
      greeting = 'Xin chào Chủ trọ! 👋\n\n'
          'Tôi là **Trợ lý Quản lý Trọ**.\n\n'
          'Tôi có thể hỗ trợ bạn:\n'
          '• Thống kê phòng trống, phòng đang thuê theo từng khu trọ.\n'
          '• Rà soát hợp đồng sắp hết hạn để kịp thời gia hạn.\n'
          '• Kiểm tra hóa đơn tiền phòng/điện nước chưa thanh toán.\n'
          '• Soạn tin đăng cho thuê phòng thu hút khách.\n\n'
          'Bạn cần tôi hỗ trợ việc gì ngay bây giờ?';
    } else if (_currentRole == 'admin') {
      greeting = 'Xin chào Quản trị viên! 🛡️\n\n'
          'Tôi là **Trợ lý Quản trị Hệ thống**.\n\n'
          'Tôi có thể hỗ trợ bạn:\n'
          '• Báo cáo tổng số tài khoản (Chủ trọ, Khách thuê, Admin).\n'
          '• Giám sát bài đăng chờ kiểm duyệt (Pending posts).\n'
          '• Theo dõi các yêu cầu bảo trì, sự cố cần xử lý.\n'
          '• Đánh giá tỷ lệ lấp đầy phòng toàn hệ thống.\n\n'
          'Bạn muốn kiểm tra số liệu nào hôm nay?';
    } else {
      greeting = 'Xin chào! 👋 Tôi là **Trợ lý Trọ Ơi**.\n\n'
          'Tôi luôn sẵn sàng hỗ trợ bạn tìm kiếm phòng trọ ưng ý, tra cứu giá thuê, tiền cọc, tiện ích và các thủ tục thuê phòng.\n\n'
          'Bạn muốn tìm phòng ở khu vực nào hay cần hỗ trợ gì?';
    }

    final welcome = ChatMessageModel(
      text: greeting,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(welcome);
    AiChatService.saveChatHistory(_currentRole, _messages);
  }

  List<String> get _quickPrompts {
    if (_currentRole == 'owner') {
      return [
        '🏢 Thống kê phòng trống & đang thuê',
        '📄 Có hợp đồng nào sắp hết hạn không?',
        '💰 Tổng hợp hóa đơn chưa thanh toán',
        '✍️ Soạn bài đăng tin cho thuê phòng',
        '⚡ Tư vấn định giá điện nước hợp lý',
      ];
    } else if (_currentRole == 'admin') {
      return [
        '📊 Thống kê tổng quan toàn hệ thống',
        '⏳ Có bao nhiêu bài đăng đang chờ duyệt?',
        '👥 Tình hình người dùng và chủ trọ',
        '🔧 Danh sách sự cố bảo trì tồn đọng',
        '📈 Tỷ lệ lấp đầy phòng toàn sàn',
      ];
    } else {
      return [
        '🔍 Tìm phòng trọ giá dưới 3 triệu',
        '⚡ Giá điện nước và dịch vụ tính thế nào?',
        '🏢 Khu trọ nào có thang máy và cho nuôi thú cưng?',
        '📋 Hướng dẫn đặt lịch xem phòng trọ',
        '📄 Quy trình ký hợp đồng và đặt cọc phòng',
      ];
    }
  }

  String get _appBarTitle {
    if (_currentRole == 'owner') return 'Trợ lý Chủ trọ';
    if (_currentRole == 'admin') return 'Trợ lý Quản trị';
    return 'Trợ lý Trọ Ơi';
  }

  String get _appBarSubtitle {
    if (_currentRole == 'owner') return 'Đang trực tuyến • Hỗ trợ quản lý';
    if (_currentRole == 'admin') return 'Đang trực tuyến • Giám sát';
    return 'Đang trực tuyến • Tư vấn tìm phòng';
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage([String? textToSend]) async {
    final text = (textToSend ?? _inputController.text).trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();

    final userMessage = ChatMessageModel(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    AiChatService.saveChatHistory(_currentRole, _messages);
    _scrollToBottom();

    try {
      final reply = await AiChatService.sendMessage(
        message: text,
        history: _messages,
        scope: _currentRole,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessageModel(
              text: reply,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
        AiChatService.saveChatHistory(_currentRole, _messages);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessageModel(
              text: 'Rất tiếc, đã có lỗi xảy ra: $e. Vui lòng thử lại sau!',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
          _isLoading = false;
        });
        AiChatService.saveChatHistory(_currentRole, _messages);
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Làm mới cuộc trò chuyện?'),
        content: const Text('Bạn có chắc muốn xóa lịch sử đoạn chat hiện tại không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AiChatService.clearChatHistory(_currentRole);
              if (!mounted) return;
              setState(() {
                _messages.clear();
                _initWelcomeMessage();
              });
            },
            child: const Text('Làm mới'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F7),
      appBar: AppBar(
        elevation: 1,
        backgroundColor: AppColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _appBarTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.fiber_manual_record, color: Colors.lightGreenAccent, size: 10),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _appBarSubtitle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới đoạn chat',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh gợi ý câu hỏi nhanh
            _buildQuickPromptsBar(),

            // Danh sách tin nhắn
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isLoading) {
                    return _buildLoadingBubble();
                  }
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Ô nhập câu hỏi
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    final prompts = _quickPrompts;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final prompt = prompts[idx];
          return ActionChip(
            backgroundColor: AppColors.lightGreen.withValues(alpha: 0.6),
            side: BorderSide(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            label: Text(
              prompt,
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            onPressed: () => _sendMessage(prompt),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primaryGreen
                    : (msg.isError ? Colors.red.shade50 : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isUser ? 0.08 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: msg.isError ? Colors.red.shade200 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    SelectableText(
                      msg.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    )
                  else if (msg.isError)
                    SelectableText(
                      msg.text,
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    )
                  else
                    MarkdownBody(
                      data: msg.text,
                      selectable: true,
                      styleSheet: _buildMarkdownStyleSheet(context),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isUser ? Colors.white70 : Colors.grey.shade400,
                        ),
                      ),
                      if (!isUser && !msg.isError) ...[
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép nội dung!'),
                                duration: Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Icon(Icons.copy_rounded, size: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.all(7),
              decoration: const BoxDecoration(
                color: AppColors.accentYellow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: const TextStyle(
        fontSize: 14.2,
        height: 1.55,
        color: Color(0xFF1E293B),
      ),
      h1: const TextStyle(
        fontSize: 17.5,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
        height: 1.4,
      ),
      h2: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
        height: 1.4,
      ),
      h3: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
        height: 1.45,
      ),
      h4: const TextStyle(
        fontSize: 14.2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
        height: 1.4,
      ),
      strong: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
      em: const TextStyle(
        fontStyle: FontStyle.italic,
        color: Color(0xFF475569),
      ),
      listBullet: const TextStyle(
        color: AppColors.primaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      listIndent: 16,
      code: TextStyle(
        fontSize: 12.5,
        backgroundColor: Colors.teal.shade50,
        color: const Color(0xFF005D4B),
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ),
      codeblockDecoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      blockquote: const TextStyle(
        fontSize: 13.5,
        color: Color(0xFF334155),
        height: 1.45,
      ),
      blockquoteDecoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.primaryGreen, width: 3.5),
        ),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.2),
        ),
      ),
      tableBody: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
      tableHead: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGreen,
      ),
      tableBorder: TableBorder.all(color: Colors.grey.shade200, width: 1),
      tableColumnWidth: const FlexColumnWidth(),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.primaryGreen,
            child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Đang soạn câu trả lời...',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _currentRole == 'owner'
                    ? 'Hỏi AI về phòng trống, hợp đồng, soạn tin...'
                    : (_currentRole == 'admin'
                        ? 'Hỏi AI về thống kê, duyệt tin, người dùng...'
                        : 'Hỏi AI về phòng, giá, dịch vụ...'),
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: const Color(0xFFF1F5F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primaryGreen,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _isLoading ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }
}
