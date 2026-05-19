// ─── features/chat/services/chat_api_service.dart ────────────────────────────
// HTTP calls for chat: open a room and load previous messages.
// Uses the same ApiService (Dio) singleton that the rest of the app uses,
// so authentication headers are injected automatically.

import '../../../core/api/api_service.dart';
import '../models/chat_message.dart';

class ChatApiService {
  final _api = ApiService();

  // ── Open (or create) the chat room for a job ──────────────────────────────
  // Returns the roomId to pass to Socket.IO.
  Future<int> getOrCreateRoom(int jobId) async {
    final response = await _api.dio.get('/chat/room/$jobId');
    final roomId = response.data['roomId'] as int;
    return roomId;
  }

  // ── Load full message history for a room ─────────────────────────────────
  // Called once when the chat screen opens, before any socket events.
  Future<List<ChatMessage>> getMessages(int roomId) async {
    final response = await _api.dio.get('/chat/messages/$roomId');
    final list = response.data as List<dynamic>;
    return list
        .map((json) => ChatMessage.fromJson(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  // ── Mark all messages in a room as read ───────────────────────────────────
  Future<void> markMessagesRead(int roomId) async {
    await _api.dio.post('/chat/messages/$roomId/read');
  }
}
