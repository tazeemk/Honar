// ─── features/chat/screens/chat_screen.dart ──────────────────────────────────
// The full-featured chat UI.
// Open this screen from the Job detail page (client or worker side).
//
// How to navigate here:
//   Navigator.push(context, MaterialPageRoute(
//     builder: (_) => ChatScreen(
//       jobId:           job['id'],
//       otherUserId:     otherUserId,   // worker's userId (from client side) or vice-versa
//       otherUserEmail:  'ali@email.com',
//     ),
//   ));

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_message.dart';
import '../services/chat_api_service.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int    jobId;          // Used to fetch/create the chat room
  final int    otherUserId;    // The person you are chatting with
  final String otherUserEmail; // Shown in the AppBar

  const ChatScreen({
    super.key,
    required this.jobId,
    required this.otherUserId,
    required this.otherUserEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // ── Services ───────────────────────────────────────────────────────────────
  final _chatApi     = ChatApiService();
  final _socket      = SocketService.instance;
  final _controller  = TextEditingController();
  final _scrollCtrl  = ScrollController();

  // ── State ──────────────────────────────────────────────────────────────────
  int?   _roomId;
  int?   _myUserId;
  bool   _loading      = true;
  bool   _otherTyping  = false;
  bool   _otherOnline  = false;
  String? _error;

  List<ChatMessage> _messages = [];

  // Debounce timer so we don't spam "stop_typing" events
  Timer? _typingTimer;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1. Get current user's ID from secure storage
    final idStr = await TokenStorage.getUserId();
    _myUserId = int.tryParse(idStr ?? '');

    // 2. Get (or create) the chat room for this job
    try {
      final roomId = await _chatApi.getOrCreateRoom(widget.jobId);
      _roomId = roomId;

      // 3. Load previous messages from the database
      final history = await _chatApi.getMessages(roomId);

      setState(() {
        _messages = history;
        _loading  = false;
      });

      // 4. Connect socket (no-op if already connected)
      await _socket.connect();

      // 5. Register callbacks BEFORE joining the room
      _socket.onMessageReceived = _onMessageReceived;
      _socket.onTyping          = _onTypingStarted;
      _socket.onStopTyping      = _onTypingStopped;
      _socket.onMessagesRead    = _onMessagesRead;
      _socket.onUserStatus      = _onUserStatus;

      // 6. Join the room so we start receiving messages
      _socket.joinRoom(roomId);

      // 7. Tell the server we've read all messages
      _socket.markRead(roomId);
      await _chatApi.markMessagesRead(roomId);

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    // Remove our callbacks so they don't fire when we're gone
    _socket.onMessageReceived = null;
    _socket.onTyping          = null;
    _socket.onStopTyping      = null;
    _socket.onMessagesRead    = null;
    _socket.onUserStatus      = null;

    _typingTimer?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Socket callbacks ───────────────────────────────────────────────────────

  void _onMessageReceived(ChatMessage msg) {
    if (!mounted) return;
    setState(() => _messages.add(msg));

    // Auto-mark as read if we received it
    if (msg.receiverId == _myUserId && _roomId != null) {
      _socket.markRead(_roomId!);
    }

    _scrollToBottom();
  }

  void _onTypingStarted(int userId) {
    if (userId != _myUserId && mounted) {
      setState(() => _otherTyping = true);
      _scrollToBottom();
    }
  }

  void _onTypingStopped(int userId) {
    if (userId != _myUserId && mounted) {
      setState(() => _otherTyping = false);
    }
  }

  void _onMessagesRead(int roomId) {
    // Update all our sent messages to show "read" ticks
    if (!mounted) return;
    setState(() {
      _messages = _messages.map((m) {
        if (m.senderId == _myUserId) return m.copyWithRead();
        return m;
      }).toList();
    });
  }

  void _onUserStatus(int userId, bool isOnline) {
    if (userId == widget.otherUserId && mounted) {
      setState(() => _otherOnline = isOnline);
    }
  }

  // ── Send message ───────────────────────────────────────────────────────────

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _roomId == null || _myUserId == null) return;

    _socket.sendMessage(_roomId!, widget.otherUserId, text);
    _controller.clear();

    // Stop the typing indicator when we actually send
    _typingTimer?.cancel();
    _socket.emitStopTyping(_roomId!);
  }

  // ── Typing indicator ───────────────────────────────────────────────────────

  void _onTextChanged(String value) {
    if (_roomId == null) return;

    if (value.isNotEmpty) {
      _socket.emitTyping(_roomId!);
    }

    // After 1.5 s of inactivity, emit stop_typing
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_roomId != null) _socket.emitStopTyping(_roomId!);
    });
  }

  // ── Scroll helpers ─────────────────────────────────────────────────────────

  void _scrollToBottom() {
    // Small delay so the list has time to build the new item
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : Column(
                  children: [
                    Expanded(child: _buildMessageList()),
                    if (_otherTyping) _buildTypingIndicator(),
                    _buildInputBar(),
                  ],
                ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar with online dot
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                child: Text(
                  widget.otherUserEmail.isNotEmpty
                      ? widget.otherUserEmail[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (_otherOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserEmail,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
              Text(
                _otherOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 11,
                  color: _otherOnline ? Colors.greenAccent : Colors.white54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet.\nSay hello! 👋',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg    = _messages[index];
        final isMe   = msg.senderId == _myUserId;
        return _MessageBubble(message: msg, isMe: isMe);
      },
    );
  }

  // Animated "..." bubble shown when the other person is typing
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _Dot(delay: i * 200)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: _onTextChanged,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: const Color(0xFFF0F4FF),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              backgroundColor: AppColors.primary,
              elevation: 0,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () { setState(() { _loading = true; _error = null; }); _init(); },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message bubble widget ────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe; // true = right side (blue), false = left side (white)

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time = '${message.createdAt.hour.toString().padLeft(2, '0')}:'
        '${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4  : 18),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 14.5,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.grey,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  // Read receipt: double tick turns blue-ish when read
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 13,
                    color: message.isRead ? Colors.lightBlueAccent : Colors.white54,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated typing dot ──────────────────────────────────────────────────────

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF0A4DA2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
