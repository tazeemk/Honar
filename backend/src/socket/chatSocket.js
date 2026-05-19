// ─── socket/chatSocket.js ────────────────────────────────────────────────────
// ALL real-time chat logic lives here.
// Important rules followed:
//   • NEVER use io.emit() globally – all messages stay inside rooms
//   • Each job has its own Socket.IO room named  "room_<roomId>"
//   • JWT is verified on every socket connection (not just HTTP)

const jwt        = require('jsonwebtoken');
const { ChatRoom, Message, User } = require('../models');

// Track which users are online: { userId → socketId }
const onlineUsers = new Map();

module.exports = (io) => {
  // ── Middleware: verify JWT before allowing any socket connection ────────────
  io.use((socket, next) => {
    // Flutter sends the token in socket.handshake.auth.token
    const token = socket.handshake.auth?.token;

    if (!token) {
      return next(new Error('Authentication error: no token provided'));
    }

    try {
      // Decode the token – same secret as authMiddleware.js
      const user = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
      socket.user = user; // attach decoded user to socket for later use
      next();
    } catch (err) {
      return next(new Error('Authentication error: invalid token'));
    }
  });

  // ── Connection handler ──────────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const userId = socket.user.id;
    console.log(`🟢 Socket connected  userId=${userId}  socketId=${socket.id}`);

    // Mark this user as online and tell everyone who cares
    onlineUsers.set(userId, socket.id);
    io.emit('user_status', { userId, isOnline: true }); // broadcast presence

    // ── Event: join_room ──────────────────────────────────────────────────────
    // Flutter calls this as soon as the chat screen opens.
    // roomId comes from the REST API (GET /api/chat/room/:jobId).
    socket.on('join_room', async ({ roomId }) => {
      try {
        // Verify the user actually belongs to this room
        const room = await ChatRoom.findByPk(roomId);
        if (!room) {
          socket.emit('error', { message: 'Chat room not found' });
          return;
        }

        if (room.clientId !== userId && room.workerId !== userId) {
          socket.emit('error', { message: 'Not authorised for this room' });
          return;
        }

        // Join the Socket.IO room
        const roomName = `room_${roomId}`;
        socket.join(roomName);
        console.log(`👤 userId=${userId} joined ${roomName}`);

        socket.emit('joined_room', { roomId, roomName });
      } catch (err) {
        console.error('join_room error:', err);
        socket.emit('error', { message: 'Could not join room' });
      }
    });

    // ── Event: send_message ───────────────────────────────────────────────────
    // Flutter emits this when the user presses Send.
    // Payload: { roomId, receiverId, message }
    socket.on('send_message', async ({ roomId, receiverId, message }) => {
      try {
        // Basic validation
        if (!roomId || !receiverId || !message?.trim()) {
          socket.emit('error', { message: 'roomId, receiverId and message are required' });
          return;
        }

        // Confirm the room exists and sender belongs to it
        const room = await ChatRoom.findByPk(roomId);
        if (!room) { socket.emit('error', { message: 'Room not found' }); return; }
        if (room.clientId !== userId && room.workerId !== userId) {
          socket.emit('error', { message: 'Not authorised' });
          return;
        }

        // Save to database so history is never lost
        const saved = await Message.create({
          chatRoomId: roomId,
          senderId:   userId,
          receiverId: parseInt(receiverId),
          message:    message.trim(),
          isRead:     false,
        });

        // Load sender info to attach to the payload
        const sender = await User.findByPk(userId, {
          attributes: ['id', 'email'],
        });

        // Build the full message payload
        const payload = {
          id:         saved.id,
          chatRoomId: saved.chatRoomId,
          senderId:   saved.senderId,
          receiverId: saved.receiverId,
          message:    saved.message,
          isRead:     saved.isRead,
          createdAt:  saved.createdAt,
          Sender:     { id: sender.id, email: sender.email },
        };

        // Emit ONLY to users inside this room – never globally
        const roomName = `room_${roomId}`;
        io.to(roomName).emit('receive_message', payload);

        console.log(`💬 Message saved  room=${roomName}  from=${userId}`);
      } catch (err) {
        console.error('send_message error:', err);
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    // ── Event: typing ─────────────────────────────────────────────────────────
    // Flutter emits this while the user is typing (throttled on the client).
    // Payload: { roomId }
    socket.on('typing', ({ roomId }) => {
      const roomName = `room_${roomId}`;
      // Tell everyone ELSE in the room (not the typer themselves)
      socket.to(roomName).emit('typing', { userId, roomId });
    });

    // ── Event: stop_typing ────────────────────────────────────────────────────
    // Flutter emits this when the user stops typing (debounced on the client).
    socket.on('stop_typing', ({ roomId }) => {
      const roomName = `room_${roomId}`;
      socket.to(roomName).emit('stop_typing', { userId, roomId });
    });

    // ── Event: mark_read ─────────────────────────────────────────────────────
    // Flutter emits this when the user has seen the messages.
    // Payload: { roomId }
    socket.on('mark_read', async ({ roomId }) => {
      try {
        // Update DB: all messages sent TO this user in this room → isRead = true
        await Message.update(
          { isRead: true },
          {
            where: {
              chatRoomId: roomId,
              receiverId: userId,
              isRead:     false,
            },
          }
        );

        // Notify the OTHER user in the room so their UI updates the ticks
        const roomName = `room_${roomId}`;
        socket.to(roomName).emit('messages_read', { roomId, readBy: userId });

        console.log(`✅ Messages read  room=${roomName}  by=${userId}`);
      } catch (err) {
        console.error('mark_read error:', err);
      }
    });

    // ── Disconnect ────────────────────────────────────────────────────────────
    socket.on('disconnect', () => {
      onlineUsers.delete(userId);
      io.emit('user_status', { userId, isOnline: false });
      console.log(`🔴 Socket disconnected  userId=${userId}`);
    });
  });
};
