// ─── models/Message.js ───────────────────────────────────────────────────────
// Every chat message sent between client and worker is stored here.
// is_read lets us show "read receipts" (blue ticks) in the UI.

module.exports = (sequelize, DataTypes) => {
  const Message = sequelize.define('Message', {
    // Which chat room this message belongs to
    chatRoomId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // User who sent the message
    senderId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // User who should receive the message
    receiverId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // The actual text of the message
    message: {
      type: DataTypes.TEXT,
      allowNull: false,
    },

    // false = not yet seen by receiver, true = receiver has seen it
    isRead: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
  });

  return Message;
};
