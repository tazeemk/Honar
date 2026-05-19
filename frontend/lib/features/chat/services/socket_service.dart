// ─── features/chat/services/socket_service.dart ──────────────────────────────
// Singleton that manages the ONE Socket.IO connection for the entire app.
// Import this wherever you need real-time chat.
//
// Usage:
//   await SocketService.instance.connect();
//   SocketService.instance.joinRoom(roomId);
//   SocketService.instance.sendMessage(roomId, receiverId, 'Hello!');
//   SocketService.instance.dispose(); // call on logout

import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../core/storage/token_storage.dart';
import '../models/chat_message.dart';

// ─── Change this to your machine's local IP when testing on a real phone ─────
// For Android emulator use 10.0.2.2; for a real phone use your WiFi IP.
// Example: 'http://192.168.1.5:5000'
const String kSocketUrl = 'http://192.168.1.39:5000';

class SocketService {
  // Private constructor – use SocketService.instance everywhere
  SocketService._();
  static final SocketService instance = SocketService._();

  IO.Socket? _socket;

  // ── Callbacks that the ChatScreen will attach to ──────────────────────────
  // Called whenever a new message arrives in the joined room
  void Function(ChatMessage)? onMessageReceived;

  // Called while the other user is typing
  void Function(int userId)? onTyping;

  // Called when the other user stops typing
  void Function(int userId)? onStopTyping;

  // Called when the other user reads our messages
  void Function(int roomId)? onMessagesRead;

  // Called with (userId, isOnline) to update online/offline badge
  void Function(int userId, bool isOnline)? onUserStatus;

  // ── Connect to the server ─────────────────────────────────────────────────
  Future<void> connect() async {
    // Don't open a second connection if one already exists
    if (_socket != null && _socket!.connected) return;

    // We need the JWT access token to authenticate the socket
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      print('⚠️  SocketService: no access token, cannot connect');
      return;
    }

    _socket = IO.io(
      kSocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // websocket only, no polling
          .disableAutoConnect() // we'll call connect() manually
          .setAuth({'token': token}) // JWT sent in handshake
          .build(),
    );

    // ── Register global socket event listeners ─────────────────────────────

    _socket!.onConnect((_) {
      print('🟢 SocketService connected  id=${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      print('🔴 SocketService disconnected');
    });

    _socket!.onConnectError((err) {
      print('❌ SocketService connect error: $err');
    });

    // New message arriving from the server
    _socket!.on('receive_message', (data) {
      try {
        final msg = ChatMessage.fromJson(
          Map<String, dynamic>.from(data as Map),
        );
        onMessageReceived?.call(msg);
      } catch (e) {
        print('❌ receive_message parse error: $e');
      }
    });

    // Other user is typing
    _socket!.on('typing', (data) {
      final userId = (data as Map)['userId'] as int?;
      if (userId != null) onTyping?.call(userId);
    });

    // Other user stopped typing
    _socket!.on('stop_typing', (data) {
      final userId = (data as Map)['userId'] as int?;
      if (userId != null) onStopTyping?.call(userId);
    });

    // Other user read our messages
    _socket!.on('messages_read', (data) {
      final roomId = (data as Map)['roomId'] as int?;
      if (roomId != null) onMessagesRead?.call(roomId);
    });

    // Online / offline status update
    _socket!.on('user_status', (data) {
      final m = data as Map;
      final userId = m['userId'] as int?;
      final isOnline = m['isOnline'] as bool? ?? false;
      if (userId != null) onUserStatus?.call(userId, isOnline);
    });

    _socket!.connect();
  }

  // ── Join a specific chat room ─────────────────────────────────────────────
  void joinRoom(int roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  // ── Send a message ────────────────────────────────────────────────────────
  void sendMessage(int roomId, int receiverId, String message) {
    _socket?.emit('send_message', {
      'roomId': roomId,
      'receiverId': receiverId,
      'message': message,
    });
  }

  // ── Typing indicators ─────────────────────────────────────────────────────
  void emitTyping(int roomId) {
    _socket?.emit('typing', {'roomId': roomId});
  }

  void emitStopTyping(int roomId) {
    _socket?.emit('stop_typing', {'roomId': roomId});
  }

  // ── Mark messages as read ─────────────────────────────────────────────────
  void markRead(int roomId) {
    _socket?.emit('mark_read', {'roomId': roomId});
  }

  // ── Disconnect (call on logout) ───────────────────────────────────────────
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;

    // Clear callbacks so they don't fire after logout
    onMessageReceived = null;
    onTyping = null;
    onStopTyping = null;
    onMessagesRead = null;
    onUserStatus = null;

    print('🔌 SocketService disposed');
  }

  bool get isConnected => _socket?.connected == true;
}
