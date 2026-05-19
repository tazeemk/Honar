// ─── models/ChatRoom.js ──────────────────────────────────────────────────────
// Each job gets ONE chat room shared between the client and worker.
// This keeps messages private – no global broadcasting.

module.exports = (sequelize, DataTypes) => {
  const ChatRoom = sequelize.define('ChatRoom', {
    // The job this room belongs to (one room per job)
    jobId: {
      type: DataTypes.INTEGER,
      allowNull: false,
      unique: true, // one chat room per job only
    },

    // The client who posted the job
    clientId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },

    // The worker assigned to the job
    workerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
  });

  return ChatRoom;
};
