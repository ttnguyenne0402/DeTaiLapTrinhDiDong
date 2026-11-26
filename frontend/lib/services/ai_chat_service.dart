import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_storage.dart';

class ChatMessageModel {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessageModel({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) => ChatMessageModel(
        text: json['text']?.toString() ?? '',
        isUser: json['isUser'] == true,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
            : DateTime.now(),
        isError: json['isError'] == true,
      );
}

class AiChatService {
  // Cổng HTTP 5093 kết nối tới Backend Web API trên Android Emulator
  static const String baseUrl = 'http://10.0.2.2:5093';

  // API Key trực tiếp để fallback khi backend chưa chạy
  static final String directApiKey = utf8.decode(base64.decode('QVEuQWI4Uk42STh6bDh0S3FBcFJGa2Q4TmNiZG1sUjR3S2V3Vlc3NHQ0TVloV2VmeHRtQ2c='));
  static const String directModel = 'gemini-3.5-flash-lite';
  static const String _storagePrefix = 'ai_chat_history_';

  static Future<String> _getStorageKey(String scope) async {
    final userId = await AuthStorage.getUserId();
    final cleanUser = (userId != null && userId.isNotEmpty) ? userId : 'guest';
    return '$_storagePrefix${scope}_$cleanUser';
  }

  /// Nạp lịch sử chat đã lưu theo vai trò (owner, tenant, admin) và tài khoản
  static Future<List<ChatMessageModel>> loadChatHistory(String scope) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey(scope);
      final jsonString = prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List decoded = jsonDecode(jsonString);
        return decoded
            .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch sử chat: $e');
    }
    return [];
  }

  /// Lưu lịch sử chat theo vai trò và tài khoản (giữ tối đa 40 tin nhắn gần nhất)
  static Future<void> saveChatHistory(String scope, List<ChatMessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey(scope);
      final subList = messages.length > 40
          ? messages.sublist(messages.length - 40)
          : messages;
      final list = subList
          .map((m) => m.toJson())
          .toList();
      await prefs.setString(key, jsonEncode(list));
    } catch (e) {
      debugPrint('Lỗi lưu lịch sử chat: $e');
    }
  }

  /// Xóa lịch sử chat khi người dùng bấm nút Làm mới
  static Future<void> clearChatHistory(String scope) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey(scope);
      await prefs.remove(key);
      await prefs.remove('$_storagePrefix$scope');
    } catch (e) {
      debugPrint('Lỗi xóa lịch sử chat: $e');
    }
  }

  /// Xóa sạch toàn bộ lịch sử chat AI khi người dùng Đăng xuất
  static Future<void> clearAllChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_storagePrefix)).toList();
      for (final k in keys) {
        await prefs.remove(k);
      }
      debugPrint('Đã xóa sạch toàn bộ lịch sử AI chat.');
    } catch (e) {
      debugPrint('Lỗi xóa toàn bộ lịch sử AI chat: $e');
    }
  }

  /// Gửi câu hỏi đến Backend để đọc trực tiếp dữ liệu mới nhất từ SQL Server
  static Future<String> sendMessage({
    required String message,
    required List<ChatMessageModel> history,
    String scope = 'tenant',
  }) async {
    try {
      final userId = await AuthStorage.getUserId();

      // Định dạng lịch sử chat
      final historyPayload = history
          .where((m) => !m.isError)
          .map((m) => {
                'role': m.isUser ? 'user' : 'model',
                'text': m.text,
              })
          .toList();

      final payload = {
        'message': message,
        'history': historyPayload,
        'userId': userId,
        'scope': scope,
      };

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/AiChat/chat'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['reply'] != null) {
          return data['reply'].toString().trim();
        } else if (data['error'] != null) {
          throw Exception(data['error']);
        }
      }

      // Nếu backend trả về lỗi hoặc chưa sẵn sàng, gọi trực tiếp Gemini với prompt cơ bản
      debugPrint('Backend AI trả về mã ${response.statusCode}, chuyển sang Direct Gemini Call');
      return await _callDirectGemini(message, history, scope);
    } catch (e) {
      debugPrint('Lỗi kết nối Backend AI ($e), đang thử gọi trực tiếp Gemini API...');
      return await _callDirectGemini(message, history, scope);
    }
  }

  /// Gọi trực tiếp Google Gemini API trong trường hợp Backend offline
  static Future<String> _callDirectGemini(
    String message,
    List<ChatMessageModel> history,
    String scope,
  ) async {
    try {
      final endpoint =
          'https://generativelanguage.googleapis.com/v1beta/models/$directModel:generateContent?key=$directApiKey';

      final contents = <Map<String, dynamic>>[];
      for (final h in history.where((m) => !m.isError).take(6)) {
        contents.add({
          'role': h.isUser ? 'user' : 'model',
          'parts': [
            {'text': h.text}
          ]
        });
      }

      contents.add({
        'role': 'user',
        'parts': [
          {'text': message}
        ]
      });

      String systemText;
      if (scope == 'owner') {
        systemText =
            'Bạn là Trợ lý AI Quản lý Trọ chuyên nghiệp dành cho Chủ trọ. Hãy hỗ trợ tư vấn quản lý phòng trọ, tối ưu doanh thu, hỗ trợ soạn tin đăng và giải quyết sự cố bằng tiếng Việt.';
      } else if (scope == 'admin') {
        systemText =
            'Bạn là Trợ lý AI Quản trị viên của ứng dụng Trọ Ơi. Hãy hỗ trợ báo cáo thống kê, quản trị vận hành và giám sát hệ thống bằng tiếng Việt.';
      } else {
        systemText =
            'Bạn là Trợ lý AI Trọ Ơi. Hãy tư vấn, hướng dẫn tìm phòng trọ, giải thích giá thuê, tiện ích và hỗ trợ khách thuê phòng một cách nhiệt tình, lịch sự bằng tiếng Việt.';
      }

      final body = {
        'systemInstruction': {
          'parts': [
            {
              'text': systemText,
            }
          ]
        },
        'contents': contents,
      };

      final res = await http
          .post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final json = jsonDecode(utf8.decode(res.bodyBytes));
        final candidates = json['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts
                .where((p) => p['thought'] != true && p['text'] != null)
                .map((p) => p['text'].toString())
                .join('')
                .trim();
            if (text.isNotEmpty) return text;
          }
        }
      }
      return 'Xin lỗi, hiện tại tôi chưa thể kết nối với hệ thống AI. Vui lòng thử lại sau ít phút!';
    } catch (e) {
      return 'Không thể kết nối tới máy chủ AI ($e). Vui lòng kiểm tra lại kết nối mạng!';
    }
  }
}
