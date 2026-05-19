// ─── controllers/chatController.js ──────────────────────────────────────────
// REST API controller for chat rooms and message history.
// Socket.IO handles the real-time part; this file handles the HTTP part.

const { ChatRoom, Message, User, Job } = require('../models');

// ─── GET /api/chat/room/:jobId ────────────────────────────────────────────────
// Get (or auto-create) the chat room for a given job.
// Only the client or worker assigned to that job can access it.
const getOrCreateRoom = async (req, res) => {
  try {
    const jobId = parseInt(req.params.jobId);
    const userId = req.user.id;

    // Find the job first – we need clientId and workerId
    const job = await Job.findByPk(jobId);
    if (!job) return res.status(404).json({ message: 'Job not found' });

    // Security: only the two parties involved can open this chat
    if (job.clientId !== userId && job.workerId !== userId) {
      return res.status(403).json({ message: 'Not authorised for this chat room' });
    }

    // Job must be accepted before chatting
    if (job.status !== 'accepted') {
      return res.status(400).json({ message: 'Chat is only available for accepted jobs' });
    }

    // Find existing room, or create a new one
    const [room, created] = await ChatRoom.findOrCreate({
      where: { jobId },
      defaults: {
        jobId,
        clientId: job.clientId,
        workerId: job.workerId,
      },
    });

    res.json({ roomId: room.id, jobId: room.jobId, created });
  } catch (err) {
    console.error('getOrCreateRoom error:', err);
    res.status(500).json({ message: err.message });
  }
};

// ─── GET /api/chat/messages/:roomId ──────────────────────────────────────────
// Load all previous messages for a chat room (chat history).
// Flutter calls this when the chat screen opens.
const getMessages = async (req, res) => {
  try {
    const roomId = parseInt(req.params.roomId);
    const userId = req.user.id;

    // Make sure this user belongs to the room
    const room = await ChatRoom.findByPk(roomId);
    if (!room) return res.status(404).json({ message: 'Chat room not found' });

    if (room.clientId !== userId && room.workerId !== userId) {
      return res.status(403).json({ message: 'Not authorised for this chat room' });
    }

    // Fetch messages oldest-first so the UI can render them top-to-bottom
    const messages = await Message.findAll({
      where: { chatRoomId: roomId },
      include: [
        {
          model: User,
          as: 'Sender',
          attributes: ['id', 'email'], // only safe fields
        },
      ],
      order: [['createdAt', 'ASC']],
    });

    res.json(messages);
  } catch (err) {
    console.error('getMessages error:', err);
    res.status(500).json({ message: err.message });
  }
};

// ─── POST /api/chat/messages/:roomId/read ────────────────────────────────────
// Mark all unread messages in a room as read for the current user.
// Called when the user opens the chat screen.
const markMessagesRead = async (req, res) => {
  try {
    const roomId = parseInt(req.params.roomId);
    const userId = req.user.id;

    // Only update messages that were sent TO this user and not yet read
    await Message.update(
      { isRead: true },
      {
        where: {
          chatRoomId: roomId,
          receiverId: userId,
          isRead: false,
        },
      }
    );

    res.json({ message: 'Messages marked as read' });
  } catch (err) {
    console.error('markMessagesRead error:', err);
    res.status(500).json({ message: err.message });
  }
};

module.exports = { getOrCreateRoom, getMessages, markMessagesRead };
