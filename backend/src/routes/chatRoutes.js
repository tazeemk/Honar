// ─── routes/chatRoutes.js ────────────────────────────────────────────────────
// HTTP routes for chat room management and message history.
// All routes require a valid JWT access token.

const router = require('express').Router();
const auth   = require('../middleware/authMiddleware');
const {
  getOrCreateRoom,
  getMessages,
  markMessagesRead,
} = require('../controllers/chatController');

// GET  /api/chat/room/:jobId        → get or create a room for a job
router.get('/room/:jobId',           auth, getOrCreateRoom);

// GET  /api/chat/messages/:roomId   → load full chat history
router.get('/messages/:roomId',      auth, getMessages);

// POST /api/chat/messages/:roomId/read → mark messages as read
router.post('/messages/:roomId/read', auth, markMessagesRead);

module.exports = router;
