// ─── features/chat/models/chat_message.dart ──────────────────────────────────
// Plain Dart class that represents one message.
// fromJson() parses the payload sent by the backend socket.

class ChatMessage {
  final int id;
  final int chatRoomId;
  final int senderId;
  final int receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String senderEmail; // e.g. "john@email.com"

  const ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.senderEmail,
  });

  // Build a ChatMessage from the JSON the server sends over the socket
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id:          json['id'] as int,
      chatRoomId:  json['chatRoomId'] as int,
      senderId:    json['senderId'] as int,
      receiverId:  json['receiverId'] as int,
      message:     json['message'] as String,
      isRead:      json['isRead'] == true,
      createdAt:   DateTime.parse(json['createdAt'] as String),
      senderEmail: (json['Sender']?['email'] as String?) ?? '',
    );
  }

  // Return a copy with isRead set to true (for read-receipt updates)
  ChatMessage copyWithRead() => ChatMessage(
        id:          id,
        chatRoomId:  chatRoomId,
        senderId:    senderId,
        receiverId:  receiverId,
        message:     message,
        isRead:      true,
        createdAt:   createdAt,
        senderEmail: senderEmail,
      );
}
